load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "file.go",
        "file_unix.go",
        "file_windows.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/docker/cli/cli/config/configfile",
    importpath = "github.com/docker/cli/cli/config/configfile",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/docker/cli/cli/config/credentials:go_default_library",
        "//vendor/github.com/docker/cli/cli/config/types:go_default_library",
        "//vendor/github.com/pkg/errors:go_default_library",
        "//vendor/github.com/sirupsen/logrus:go_default_library",
    ],
)
