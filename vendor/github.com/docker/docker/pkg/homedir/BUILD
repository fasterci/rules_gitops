load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "homedir_linux.go",
        "homedir_others.go",
        "homedir_unix.go",
        "homedir_windows.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/docker/docker/pkg/homedir",
    importpath = "github.com/docker/docker/pkg/homedir",
    visibility = ["//visibility:public"],
)
