load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["versioning.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/runtime/serializer/versioning",
    importpath = "k8s.io/apimachinery/pkg/runtime/serializer/versioning",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1/unstructured:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime/schema:go_default_library",
        "//vendor/k8s.io/klog/v2:go_default_library",
    ],
)
