load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["streaming.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/runtime/serializer/streaming",
    importpath = "k8s.io/apimachinery/pkg/runtime/serializer/streaming",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime/schema:go_default_library",
    ],
)
