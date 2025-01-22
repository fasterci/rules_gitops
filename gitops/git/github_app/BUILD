load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["github_app.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/github_app",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/bradleyfalzon/ghinstallation/v2:go_default_library",
        "//vendor/github.com/google/go-github/v58/github:go_default_library",
    ],
)