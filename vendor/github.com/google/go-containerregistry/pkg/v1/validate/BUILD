load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "image.go",
        "index.go",
        "layer.go",
        "options.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/validate",
    importpath = "github.com/google/go-containerregistry/pkg/v1/validate",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-cmp/cmp:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/partial:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)
