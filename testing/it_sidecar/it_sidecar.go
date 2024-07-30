package main

import (
	"bufio"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/fasterci/rules_gitops/testing/it_sidecar/stern"

	v1 "k8s.io/api/core/v1"
	meta_v1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/informers"
	"k8s.io/client-go/kubernetes"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/cache"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/portforward"
	"k8s.io/client-go/transport/spdy"
	"k8s.io/client-go/util/homedir"
)

type portForwardConf struct {
	services map[string][]uint16
}

func (i *portForwardConf) String() string {
	return fmt.Sprintf("%v", i.services)
}

func (i *portForwardConf) Set(value string) error {
	v := strings.SplitN(value, ":", 2)
	if len(v) != 2 {
		return fmt.Errorf("incorrect portforward '%s': must be in form of service:port", value)
	}
	port, err := strconv.ParseUint(v[1], 10, 16)
	if err != nil {
		return fmt.Errorf("incorrect port in portforward '%s': %v", value, err)
	}
	i.services[v[0]] = append(i.services[v[0]], uint16(port))
	return nil
}

type arrayFlags []string

func (i *arrayFlags) String() string {
	return "my string representation"
}

func (i *arrayFlags) Set(value string) error {
	*i = append(*i, value)
	return nil
}

var (
	namespace      = flag.String("namespace", os.Getenv("NAMESPACE"), "kubernetes namespace")
	timeout        = flag.Duration("timeout", time.Second*30, "execution timeout")
	pfconfig       = portForwardConf{services: make(map[string][]uint16)}
	kubeconfig     string
	waitForApps    arrayFlags
	allowErrors    bool
	disablePodLogs bool
)

func init() {
	flag.Var(&pfconfig, "portforward", "set a port forward item in form of servicename:port")
	flag.StringVar(&kubeconfig, "kubeconfig", os.Getenv("KUBECONFIG"), "path to kubernetes config file")
	flag.Var(&waitForApps, "waitforapp", "wait for pods with label app=<this parameter>")
	flag.BoolVar(&allowErrors, "allow_errors", false, "do not treat Failed in events as error. Use only if crashloop is expected")
	flag.BoolVar(&disablePodLogs, "disable_pod_logs", false, "do not forward pod logs")
}

// contains returns true if slice v contains an item
func contains(v []string, item string) bool {
	for _, s := range v {
		if s == item {
			return true
		}
	}
	return false
}

// listReadyApps converts a list returned from podsInformer.GetStore().List() to a map containing apps with ready status
// app is determined by app label
func listReadyApps(list []interface{}) (readypods, notReady []string) {
	var readyApps []string
	for _, it := range list {
		pod, ok := it.(*v1.Pod)
		if !ok {
			panic(errors.New("expected pod in informer"))
		}
		for _, cond := range pod.Status.Conditions {
			if cond.Type == v1.PodReady {
				if cond.Status == v1.ConditionTrue {
					readypods = append(readypods, pod.Name)
					app := pod.GetLabels()["app"]
					if app != "" {
						readyApps = append(readyApps, app)
					}
					app = pod.GetLabels()["app.kubernetes.io/name"]
					if app != "" {
						readyApps = append(readyApps, app)
					}

				}
			}
		}
	}
	for _, app := range waitForApps {
		if !contains(readyApps, app) {
			notReady = append(notReady, app)
		}
	}
	return
}

// listenForEvents listens for events and prints them to stdout. if event reason is "Failed" it will call the failure callback
func listenForEvents(ctx context.Context, clientset *kubernetes.Clientset, onFailure func(*v1.Event)) {

	kubeInformerFactory := informers.NewFilteredSharedInformerFactory(clientset, time.Second*30, *namespace, nil)
	eventsInformer := kubeInformerFactory.Core().V1().Events().Informer()

	fn := func(obj interface{}) {
		event, ok := obj.(*v1.Event)
		if !ok {
			log.Println("Event informer received unexpected object")
			return
		}
		log.Printf("EVENT %s %s %s %s\n", event.Namespace, event.InvolvedObject.Name, event.Reason, event.Message)
		if event.Reason == "Failed" || event.Reason == "BackOff" {
			onFailure(event)
		}
	}

	handler := &cache.ResourceEventHandlerFuncs{
		AddFunc:    fn,
		DeleteFunc: fn,
		UpdateFunc: func(old interface{}, new interface{}) {
			fn(new)
		},
	}

	eventsInformer.AddEventHandler(handler)

	go kubeInformerFactory.Start(ctx.Done())
}

func waitForPods(ctx context.Context, clientset *kubernetes.Clientset) error {
	events := make(chan interface{})
	fn := func(obj interface{}) {
		events <- obj
	}

	handler := &cache.ResourceEventHandlerFuncs{
		AddFunc:    fn,
		DeleteFunc: fn,
		UpdateFunc: func(old interface{}, new interface{}) {
			fn(new)
		},
	}

	kubeInformerFactory := informers.NewFilteredSharedInformerFactory(clientset, time.Second*30, *namespace, nil)
	podsInformer := kubeInformerFactory.Core().V1().Pods().Informer()
	podsInformer.AddEventHandler(handler)
	go kubeInformerFactory.Start(ctx.Done())

waitForPodsUp:
	for {
		select {
		case <-events:
			v := podsInformer.GetStore().List()
			ready, notReady := listReadyApps(v)
			log.Print("ready pods:", ready)
			if len(notReady) != 0 {
				log.Print("waiting for apps:", notReady)
			} else {
				log.Println("all apps are ready")
				break waitForPodsUp
			}
		case <-ctx.Done():
			return errors.New("timed out waiting for apps")
		}
	}
	return nil
}

// listReadyServices converts a list returned from endpointsInformer.GetStore().List() to a list of services with ready status
func listReadyServices(list []interface{}) (ready, notReady []string) {
	for _, it := range list {
		ep, ok := it.(*v1.Endpoints)
		if !ok {
			panic(errors.New("expected EndpointsList in informer"))
		}
		for _, subset := range ep.Subsets {
			if len(subset.Addresses) > 0 {
				ready = append(ready, ep.Name)
				break
			}
		}
	}
	for service, _ := range pfconfig.services {
		if !contains(ready, service) {
			notReady = append(notReady, service)
		}
	}
	return
}

func waitForEndpoints(ctx context.Context, clientset *kubernetes.Clientset, config *rest.Config) error {
	events := make(chan interface{})
	fn := func(obj interface{}) {
		events <- obj
	}

	handler := &cache.ResourceEventHandlerFuncs{
		AddFunc:    fn,
		DeleteFunc: fn,
		UpdateFunc: func(old interface{}, new interface{}) {
			fn(new)
		},
	}

	kubeInformerFactory := informers.NewFilteredSharedInformerFactory(clientset, time.Second*30, *namespace, nil)
	endpointsInformer := kubeInformerFactory.Core().V1().Endpoints().Informer()
	endpointsInformer.AddEventHandler(handler)
	go kubeInformerFactory.Start(ctx.Done())

	allReadyServices := make(map[string]bool)
waitForServicesUp:
	for {
		select {
		case <-events:
			v := endpointsInformer.GetStore().List()
			ready, notReady := listReadyServices(v)
			log.Print("ready services:", ready)
			for _, svc := range ready {
				if !allReadyServices[svc] {
					allReadyServices[svc] = true
					log.Print("SERVICE_READY ", svc)
					if ports := pfconfig.services[svc]; len(ports) > 0 {
						err := portForward(ctx, clientset, config, svc, ports)
						if err != nil {
							return err
						}
					}
				}
			}
			if len(notReady) != 0 {
				log.Print("waiting for endpoints:", notReady)
			} else {
				log.Println("all services are ready")
				break waitForServicesUp
			}
		case <-ctx.Done():
			return errors.New("timed out waiting for services")
		}
	}
	return nil
}

func portForward(ctx context.Context, clientset *kubernetes.Clientset, config *rest.Config, serviceName string, ports []uint16) error {
	// port forward
	var wg sync.WaitGroup
	wg.Add(len(ports))
	for _, port := range ports {
		ep, err := clientset.CoreV1().Endpoints(*namespace).Get(ctx, serviceName, meta_v1.GetOptions{})
		if err != nil {
			return fmt.Errorf("error listing endpoints for service %s: %v", serviceName, err)
		}
		var podnamespace, podname string
		for _, subset := range ep.Subsets {
			if len(subset.Addresses) == 0 {
				continue
			}
			podnamespace = subset.Addresses[0].TargetRef.Namespace
			podname = subset.Addresses[0].TargetRef.Name
			break
		}
		if podnamespace == "" || podname == "" {
			return fmt.Errorf("no pods are available for service %s", serviceName)
		}
		log.Printf("%s -> %s/%s", serviceName, podnamespace, podname)

		url := clientset.CoreV1().RESTClient().Post().Resource("pods").Namespace(podnamespace).Name(podname).SubResource("portforward").URL()
		transport, upgrader, err := spdy.RoundTripperFor(config)
		if err != nil {
			return fmt.Errorf("could not create round tripper: %v", err)
		}
		dialer := spdy.NewDialer(upgrader, &http.Client{Transport: transport}, "POST", url)
		ports := []string{fmt.Sprintf(":%d", port)}
		readyChan := make(chan struct{}, 1)
		pf, err := portforward.New(dialer, ports, ctx.Done(), readyChan, os.Stderr, os.Stderr)
		if err != nil {
			return fmt.Errorf("could not port forward into pod: %v", err)
		}
		go func(port uint16) {
			err := pf.ForwardPorts()
			if err != nil {
				log.Fatalf("Could not forward ports for %s:%d : %v", serviceName, port, err)
			}
		}(port)
		go func(port uint16) {
			<-pf.Ready
			ports, err := pf.GetPorts()
			if err != nil {
				log.Fatalf("Could not get forwarded ports for %s:%d : %v", serviceName, port, err)
			}
			for _, port := range ports {
				fmt.Printf("FORWARD %s:%d:%d\n", serviceName, port.Remote, port.Local)
			}
			wg.Done()
		}(port)
	}
	wg.Wait()
	return nil
}

var ErrTimedOut = errors.New("timed out")
var ErrStdinClosed = errors.New("stdin closed")
var ErrTermSignalReceived = errors.New("TERM signal received")

func main() {
	flag.Parse()
	log.SetOutput(os.Stdout)
	ctx, timeoutCancel := context.WithTimeoutCause(context.Background(), *timeout, ErrTimedOut)
	defer timeoutCancel()
	ctx, cancel := context.WithCancelCause(ctx)
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		log.Print("First TERM signal, stopping...")
		cancel(ErrTermSignalReceived)
		signal.Stop(c)
	}()
	// cancel context if stdin is closed
	go func() {
		reader := bufio.NewReader(os.Stdin)
		for {
			_, _, err := reader.ReadRune()
			if err != nil && err == io.EOF {
				cancel(ErrStdinClosed)
				break
			}
		}
	}()

	var clientset *kubernetes.Clientset
	if kubeconfig == "" {
		_, ok := os.LookupEnv("KUBERNETES_SERVICE_HOST")
		if !ok {
			kubeconfig = filepath.Join(homedir.HomeDir(), ".kube", "config")
		}
	}
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		log.Fatal(err)
	}
	clientset = kubernetes.NewForConfigOrDie(config)

	go func() {
		err := stern.Run(ctx, *namespace, clientset, allowErrors, disablePodLogs)
		if err != nil {
			log.Print(err)
		}
		cancel(fmt.Errorf("terminate due to kubernetes listening failure: %w", err))
	}()

	listenForEvents(ctx, clientset, func(event *v1.Event) {
		if !allowErrors {
			cancel(fmt.Errorf("terminate due to event %s/%s %s %s", event.Namespace, event.InvolvedObject.Name, event.Reason, event.Message))
		}
	})

	if len(waitForApps) > 0 {
		err = waitForPods(ctx, clientset)
		if err != nil {
			log.Print(err)
			return
		}
	}
	if len(pfconfig.services) > 0 {
		err = waitForEndpoints(ctx, clientset, config)
		if err != nil {
			log.Print(err)
			return
		}
	}

	fmt.Println("READY")
	<-ctx.Done()
	if cause := context.Cause(ctx); cause != nil {
		log.Print("ctx.Done: ", cause.Error())
	}

}
