load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "httpstream.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/util/httpstream",
    importpath = "k8s.io/apimachinery/pkg/util/httpstream",
    visibility = ["//visibility:public"],
)
