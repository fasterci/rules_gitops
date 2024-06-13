load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["windows.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/windows",
    importpath = "github.com/google/go-containerregistry/internal/windows",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/gzip:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/tarball:go_default_library",
    ],
)
