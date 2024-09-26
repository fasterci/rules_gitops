load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["github-app.go"],
    importpath = "github.com/nazzzzz/rules_gitops/gitops/git/github_app",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-github/v32/github:go_default_library",
        "//vendor/golang.org/x/oauth2:go_default_library",
    ],
)
