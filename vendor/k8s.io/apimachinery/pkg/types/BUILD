load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "namespacedname.go",
        "nodename.go",
        "patch.go",
        "uid.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/types",
    importpath = "k8s.io/apimachinery/pkg/types",
    visibility = ["//visibility:public"],
)
