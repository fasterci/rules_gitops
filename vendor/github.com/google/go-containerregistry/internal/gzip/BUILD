load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["zip.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/gzip",
    importpath = "github.com/google/go-containerregistry/internal/gzip",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = ["//vendor/github.com/google/go-containerregistry/internal/and:go_default_library"],
)
