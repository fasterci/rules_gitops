load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "errgroup.go",
        "go120.go",
        "pre_go120.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/sync/errgroup",
    importpath = "golang.org/x/sync/errgroup",
    visibility = ["//visibility:public"],
)
