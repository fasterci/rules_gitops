load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["compression.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/compression",
    importpath = "github.com/google/go-containerregistry/internal/compression",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/gzip:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/zstd:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/compression:go_default_library",
    ],
)
