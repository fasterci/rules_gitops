load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["handler.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/kube-openapi/pkg/handler3",
    importpath = "k8s.io/kube-openapi/pkg/handler3",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/golang/protobuf/proto:go_default_library",
        "//vendor/github.com/google/gnostic/openapiv3:go_default_library",
        "//vendor/github.com/munnerz/goautoneg:go_default_library",
        "//vendor/k8s.io/kube-openapi/pkg/common:go_default_library",
        "//vendor/k8s.io/kube-openapi/pkg/internal/handler:go_default_library",
        "//vendor/k8s.io/kube-openapi/pkg/spec3:go_default_library",
        "//vendor/k8s.io/kube-openapi/pkg/validation/spec:go_default_library",
    ],
)
