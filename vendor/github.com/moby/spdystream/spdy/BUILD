load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "dictionary.go",
        "read.go",
        "types.go",
        "write.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/moby/spdystream/spdy",
    importpath = "github.com/moby/spdystream/spdy",
    visibility = ["//visibility:public"],
)
