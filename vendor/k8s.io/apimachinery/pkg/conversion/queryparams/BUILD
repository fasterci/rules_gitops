load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "convert.go",
        "doc.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/conversion/queryparams",
    importpath = "k8s.io/apimachinery/pkg/conversion/queryparams",
    visibility = ["//visibility:public"],
)
