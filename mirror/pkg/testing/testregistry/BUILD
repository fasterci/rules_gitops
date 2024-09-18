load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "testregistry",
    srcs = ["testing.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/pkg/testing/testregistry",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/name",
        "//vendor/github.com/google/go-containerregistry/pkg/registry",
    ],
)
