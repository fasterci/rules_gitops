load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "mirror",
    srcs = ["mirror.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/pkg/mirror",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_google_go_containerregistry//pkg/authn",
        "@com_github_google_go_containerregistry//pkg/logs",
        "@com_github_google_go_containerregistry//pkg/name",
        "@com_github_google_go_containerregistry//pkg/v1:pkg",
        "@com_github_google_go_containerregistry//pkg/v1/remote",
        "@com_github_google_go_containerregistry//pkg/v1/remote/transport",
        "@com_github_google_go_containerregistry//pkg/v1/types",
    ],
)

alias(
    name = "go_default_library",
    actual = ":mirror",
    visibility = ["//visibility:public"],
)

go_test(
    name = "mirror_test",
    srcs = ["mirror_test.go"],
    deps = [
        ":mirror",
        "//mirror/pkg/testing/testregistry",
        "@com_github_google_go_containerregistry//pkg/authn",
        "@com_github_google_go_containerregistry//pkg/name",
        "@com_github_google_go_containerregistry//pkg/registry",
        "@com_github_google_go_containerregistry//pkg/v1/random",
        "@com_github_google_go_containerregistry//pkg/v1/remote",
    ],
)
