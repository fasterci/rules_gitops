load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "config.go",
        "doc.go",
        "hash.go",
        "image.go",
        "index.go",
        "layer.go",
        "manifest.go",
        "platform.go",
        "progress.go",
        "zz_deepcopy_generated.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1",
    importpath = "github.com/google/go-containerregistry/pkg/v1",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library"],
)
