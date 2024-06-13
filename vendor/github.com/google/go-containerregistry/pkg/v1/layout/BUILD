load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "blob.go",
        "doc.go",
        "gc.go",
        "image.go",
        "index.go",
        "layoutpath.go",
        "options.go",
        "read.go",
        "write.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/layout",
    importpath = "github.com/google/go-containerregistry/pkg/v1/layout",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/match:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/mutate:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/partial:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/stream:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
        "//vendor/golang.org/x/sync/errgroup:go_default_library",
    ],
)
