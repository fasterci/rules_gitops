load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["verify.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/verify",
    importpath = "github.com/google/go-containerregistry/internal/verify",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/and:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
    ],
)
