load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "client.go",
        "roundtripper.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/hashicorp/go-retryablehttp",
    importpath = "github.com/hashicorp/go-retryablehttp",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/hashicorp/go-cleanhttp:go_default_library"],
)
