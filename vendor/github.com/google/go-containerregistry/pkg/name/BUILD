load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "check.go",
        "digest.go",
        "doc.go",
        "errors.go",
        "options.go",
        "ref.go",
        "registry.go",
        "repository.go",
        "tag.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/name",
    importpath = "github.com/google/go-containerregistry/pkg/name",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/opencontainers/go-digest:go_default_library"],
)
