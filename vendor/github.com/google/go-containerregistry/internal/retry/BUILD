load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["retry.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/retry",
    importpath = "github.com/google/go-containerregistry/internal/retry",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = ["//vendor/github.com/google/go-containerregistry/internal/retry/wait:go_default_library"],
)
