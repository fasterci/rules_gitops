load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["config.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/docker/cli/cli/config",
    importpath = "github.com/docker/cli/cli/config",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/docker/cli/cli/config/configfile:go_default_library",
        "//vendor/github.com/docker/cli/cli/config/credentials:go_default_library",
        "//vendor/github.com/docker/cli/cli/config/types:go_default_library",
        "//vendor/github.com/docker/docker/pkg/homedir:go_default_library",
        "//vendor/github.com/pkg/errors:go_default_library",
    ],
)
