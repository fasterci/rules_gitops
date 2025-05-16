load("@rules_go//go:def.bzl", "go_library")

go_library(
    name = "github",
    srcs = ["github.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/github",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_google_go_github_v32//github",
        "@org_golang_x_oauth2//:oauth2",
    ],
)

alias(
    name = "go_default_library",
    actual = ":github",
    visibility = ["//visibility:public"],
)
