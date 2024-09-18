load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "github",
    srcs = ["github.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/github",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-github/v32/github",
        "//vendor/golang.org/x/oauth2",
    ],
)
