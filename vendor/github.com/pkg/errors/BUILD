load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "errors.go",
        "go113.go",
        "stack.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/pkg/errors",
    importpath = "github.com/pkg/errors",
    visibility = ["//visibility:public"],
)
