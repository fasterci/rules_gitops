load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "executor.go",
        "go_above_19.go",
        "go_below_19.go",
        "log.go",
        "unbounded_executor.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/modern-go/concurrent",
    importpath = "github.com/modern-go/concurrent",
    visibility = ["//visibility:public"],
)
