load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["from_stack.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/util/naming",
    importpath = "k8s.io/apimachinery/pkg/util/naming",
    visibility = ["//visibility:public"],
)
