load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "image.go",
        "index.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/empty",
    importpath = "github.com/google/go-containerregistry/pkg/v1/empty",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/partial:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
