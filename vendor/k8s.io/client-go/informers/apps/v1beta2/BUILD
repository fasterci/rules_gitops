load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "controllerrevision.go",
        "daemonset.go",
        "deployment.go",
        "interface.go",
        "replicaset.go",
        "statefulset.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/informers/apps/v1beta2",
    importpath = "k8s.io/client-go/informers/apps/v1beta2",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/api/apps/v1beta2:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/watch:go_default_library",
        "//vendor/k8s.io/client-go/informers/internalinterfaces:go_default_library",
        "//vendor/k8s.io/client-go/kubernetes:go_default_library",
        "//vendor/k8s.io/client-go/listers/apps/v1beta2:go_default_library",
        "//vendor/k8s.io/client-go/tools/cache:go_default_library",
    ],
)
