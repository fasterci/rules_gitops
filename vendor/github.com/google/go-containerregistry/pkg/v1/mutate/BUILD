load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "image.go",
        "index.go",
        "mutate.go",
        "rebase.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/mutate",
    importpath = "github.com/google/go-containerregistry/pkg/v1/mutate",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/gzip:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/empty:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/match:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/partial:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/stream:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/tarball:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
