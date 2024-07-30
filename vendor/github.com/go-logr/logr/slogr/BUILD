load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "sloghandler.go",
        "slogr.go",
        "slogsink.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/go-logr/logr/slogr",
    importpath = "github.com/go-logr/logr/slogr",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/go-logr/logr:go_default_library"],
)
