load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "rate.go",
        "sometimes.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/time/rate",
    importpath = "golang.org/x/time/rate",
    visibility = ["//visibility:public"],
)
