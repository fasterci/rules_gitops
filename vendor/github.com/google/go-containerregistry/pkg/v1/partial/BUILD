load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "compressed.go",
        "doc.go",
        "image.go",
        "index.go",
        "uncompressed.go",
        "with.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/partial",
    importpath = "github.com/google/go-containerregistry/pkg/v1/partial",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/and:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/compression:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/gzip:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/zstd:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/compression:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/match:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
