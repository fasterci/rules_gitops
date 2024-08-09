load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/cmd/crane",
    importpath = "github.com/google/go-containerregistry/cmd/crane",
    visibility = ["//visibility:private"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/cmd/crane/cmd:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
    ],
)

go_binary(
    name = "crane",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
