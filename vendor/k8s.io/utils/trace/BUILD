load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["trace.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/utils/trace",
    importpath = "k8s.io/utils/trace",
    visibility = ["//visibility:public"],
    deps = ["//vendor/k8s.io/klog/v2:go_default_library"],
)
