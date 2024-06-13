load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/cmd/registry",
    importpath = "github.com/google/go-containerregistry/cmd/registry",
    visibility = ["//visibility:private"],
    deps = ["//vendor/github.com/google/go-containerregistry/pkg/registry:go_default_library"],
)

go_binary(
    name = "registry",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
