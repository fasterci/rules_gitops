load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "gitlab",
    srcs = ["gitlab.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/gitlab",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/xanzy/go-gitlab"],
)

go_test(
    name = "gitlab_test",
    srcs = ["gitlab_test.go"],
    embed = [":gitlab"],
)
