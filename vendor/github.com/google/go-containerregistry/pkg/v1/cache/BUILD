load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "cache.go",
        "fs.go",
        "ro.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/cache",
    importpath = "github.com/google/go-containerregistry/pkg/v1/cache",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/tarball:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
