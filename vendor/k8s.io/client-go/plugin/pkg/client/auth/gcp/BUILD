load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["gcp_stub.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/plugin/pkg/client/auth/gcp",
    importpath = "k8s.io/client-go/plugin/pkg/client/auth/gcp",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/client-go/rest:go_default_library",
        "//vendor/k8s.io/klog/v2:go_default_library",
    ],
)
