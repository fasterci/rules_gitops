load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "json.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/sigs.k8s.io/json",
    importpath = "sigs.k8s.io/json",
    visibility = ["//visibility:public"],
    deps = ["//vendor/sigs.k8s.io/json/internal/golang/encoding/json:go_default_library"],
)
