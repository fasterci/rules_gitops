load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["handler_cache.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/kube-openapi/pkg/internal/handler",
    importpath = "k8s.io/kube-openapi/pkg/internal/handler",
    visibility = ["//vendor/k8s.io/kube-openapi/pkg:__subpackages__"],
)
