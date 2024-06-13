load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "go_default_library",
    srcs = ["mirror.go"],
    importpath = "github.com/fasterci/rules_gitops/mirror/pkg/mirror",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/pkg/authn:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote/transport:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
    ],
)

go_test(
    name = "go_default_test",
    srcs = ["mirror_test.go"],
    deps = [
        ":go_default_library",
        "//mirror/pkg/testing/testregistry:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/authn:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/registry:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/random:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote:go_default_library",
    ],
)
