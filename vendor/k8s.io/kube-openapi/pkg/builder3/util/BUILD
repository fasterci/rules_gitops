load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["util.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/kube-openapi/pkg/builder3/util",
    importpath = "k8s.io/kube-openapi/pkg/builder3/util",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/kube-openapi/pkg/schemamutation:go_default_library",
        "//vendor/k8s.io/kube-openapi/pkg/validation/spec:go_default_library",
    ],
)
