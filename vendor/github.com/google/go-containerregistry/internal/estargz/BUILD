load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["estargz.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/estargz",
    importpath = "github.com/google/go-containerregistry/internal/estargz",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/containerd/stargz-snapshotter/estargz:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
    ],
)
