load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["runtime.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/util/runtime",
    importpath = "k8s.io/apimachinery/pkg/util/runtime",
    visibility = ["//visibility:public"],
    deps = ["//vendor/k8s.io/klog/v2:go_default_library"],
)
