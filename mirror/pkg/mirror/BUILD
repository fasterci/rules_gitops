load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "mirror",
    srcs = ["mirror.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/pkg/mirror",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/authn",
        "//vendor/github.com/google/go-containerregistry/pkg/logs",
        "//vendor/github.com/google/go-containerregistry/pkg/name",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:pkg",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote/transport",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types",
    ],
)

go_test(
    name = "mirror_test",
    srcs = ["mirror_test.go"],
    deps = [
        ":mirror",
        "//mirror/pkg/testing/testregistry",
        "//vendor/github.com/google/go-containerregistry/pkg/authn",
        "//vendor/github.com/google/go-containerregistry/pkg/name",
        "//vendor/github.com/google/go-containerregistry/pkg/registry",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/random",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote",
    ],
)
