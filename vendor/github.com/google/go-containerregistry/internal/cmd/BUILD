load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["edit.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/internal/cmd",
    importpath = "github.com/google/go-containerregistry/internal/cmd",
    visibility = ["//vendor/github.com/google/go-containerregistry:__subpackages__"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/editor:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/verify:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/crane:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/mutate:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/static:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/tarball:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
        "//vendor/github.com/spf13/cobra:go_default_library",
    ],
)
