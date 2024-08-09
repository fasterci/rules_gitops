load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/cmd/mirror",
    visibility = ["//visibility:private"],
    deps = [
        "//mirror/pkg/mirror:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
    ],
)

go_binary(
    name = "mirror",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
