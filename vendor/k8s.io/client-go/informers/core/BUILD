load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["interface.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/informers/core",
    importpath = "k8s.io/client-go/informers/core",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/client-go/informers/core/v1:go_default_library",
        "//vendor/k8s.io/client-go/informers/internalinterfaces:go_default_library",
    ],
)
