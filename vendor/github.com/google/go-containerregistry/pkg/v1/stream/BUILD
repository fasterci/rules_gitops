load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["layer.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/stream",
    importpath = "github.com/google/go-containerregistry/pkg/v1/stream",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
