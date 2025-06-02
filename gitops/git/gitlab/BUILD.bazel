load("@rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "gitlab",
    srcs = ["gitlab.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/gitlab",
    visibility = ["//visibility:public"],
    deps = ["@com_github_xanzy_go_gitlab//:go-gitlab"],
)

go_test(
    name = "gitlab_test",
    srcs = ["gitlab_test.go"],
    embed = [":gitlab"],
)

alias(
    name = "go_default_library",
    actual = ":gitlab",
    visibility = ["//visibility:public"],
)
