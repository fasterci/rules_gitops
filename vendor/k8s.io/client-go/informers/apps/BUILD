load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["interface.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/informers/apps",
    importpath = "k8s.io/client-go/informers/apps",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/client-go/informers/apps/v1:go_default_library",
        "//vendor/k8s.io/client-go/informers/apps/v1beta1:go_default_library",
        "//vendor/k8s.io/client-go/informers/apps/v1beta2:go_default_library",
        "//vendor/k8s.io/client-go/informers/internalinterfaces:go_default_library",
    ],
)
