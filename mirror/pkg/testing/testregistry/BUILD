load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "testregistry",
    srcs = ["testing.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/pkg/testing/testregistry",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_google_go_containerregistry//pkg/name",
        "@com_github_google_go_containerregistry//pkg/registry",
    ],
)

alias(
    name = "go_default_library",
    actual = ":testregistry",
    visibility = ["//visibility:public"],
)
