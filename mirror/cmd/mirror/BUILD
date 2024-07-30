load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "mirror_lib",
    srcs = ["main.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/cmd/mirror",
    visibility = ["//visibility:private"],
    deps = [
        "//mirror/pkg/mirror",
        "//vendor/github.com/google/go-containerregistry/pkg/logs",
    ],
)

go_binary(
    name = "mirror",
    embed = [":mirror_lib"],
    visibility = ["//visibility:public"],
)
