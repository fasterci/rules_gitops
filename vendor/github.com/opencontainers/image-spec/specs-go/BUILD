load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "version.go",
        "versioned.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/opencontainers/image-spec/specs-go",
    importpath = "github.com/opencontainers/image-spec/specs-go",
    visibility = ["//visibility:public"],
)
