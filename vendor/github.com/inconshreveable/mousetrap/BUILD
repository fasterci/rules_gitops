load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "trap_others.go",
        "trap_windows.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/inconshreveable/mousetrap",
    importpath = "github.com/inconshreveable/mousetrap",
    visibility = ["//visibility:public"],
)
