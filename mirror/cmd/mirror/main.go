package main

import (
	"context"
	"flag"
	"os"
	"os/signal"
	"time"

	"github.com/fasterci/rules_gitops/mirror/pkg/mirror"
	"github.com/google/go-containerregistry/pkg/logs"
)

var (
	Timeout      time.Duration
	FromLocation string
	To           string
	Digest       string
)

func init() {
	logs.Warn.SetOutput(os.Stderr)
	logs.Progress.SetOutput(os.Stderr)
	flag.DurationVar(&Timeout, "timeout", time.Second*30, "Timeout for the mirror operation")
	flag.StringVar(&FromLocation, "from", "", "The location of the image to mirror, required")
	flag.StringVar(&To, "to", "", "The location of the mirror destination, required")
	flag.StringVar(&Digest, "digest", "", "The digest of the image, like sha256:1234, required")
}

func main() {
	flag.Parse()
	// verify that the flags are set
	if FromLocation == "" || To == "" || Digest == "" {
		flag.Usage()
		os.Exit(1)
	}

	ctx, cancelT := context.WithTimeout(context.Background(), Timeout)
	defer cancelT()
	ctx, cancel := signal.NotifyContext(ctx, os.Interrupt)
	defer cancel()
	if err := mirror.ExecuteContext(ctx, FromLocation, To, Digest); err != nil {
		logs.Warn.Printf("Failed to mirror %s to %s: %v", FromLocation, To, err)
		os.Exit(1)
	}
}
