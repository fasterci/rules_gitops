load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "credentials.go",
        "error.go",
        "helper.go",
        "version.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/docker/docker-credential-helpers/credentials",
    importpath = "github.com/docker/docker-credential-helpers/credentials",
    visibility = ["//visibility:public"],
)
