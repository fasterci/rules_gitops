load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["zstd.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/zstd",
    importpath = "github.com/google/go-containerregistry/internal/zstd",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/and:go_default_library",
        "//vendor/github.com/klauspost/compress/zstd:go_default_library",
    ],
)
