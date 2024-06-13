load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["redact.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/redact",
    importpath = "github.com/google/go-containerregistry/internal/redact",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
)
