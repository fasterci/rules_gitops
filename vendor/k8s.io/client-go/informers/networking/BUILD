load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["interface.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/informers/networking",
    importpath = "k8s.io/client-go/informers/networking",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/client-go/informers/internalinterfaces:go_default_library",
        "//vendor/k8s.io/client-go/informers/networking/v1:go_default_library",
        "//vendor/k8s.io/client-go/informers/networking/v1alpha1:go_default_library",
        "//vendor/k8s.io/client-go/informers/networking/v1beta1:go_default_library",
    ],
)
