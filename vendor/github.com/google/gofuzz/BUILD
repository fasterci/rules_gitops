load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "fuzz.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/gofuzz",
    importpath = "github.com/google/gofuzz",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/google/gofuzz/bytesource:go_default_library"],
)
