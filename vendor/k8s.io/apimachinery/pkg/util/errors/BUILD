load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "errors.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/util/errors",
    importpath = "k8s.io/apimachinery/pkg/util/errors",
    visibility = ["//visibility:public"],
    deps = ["//vendor/k8s.io/apimachinery/pkg/util/sets:go_default_library"],
)
