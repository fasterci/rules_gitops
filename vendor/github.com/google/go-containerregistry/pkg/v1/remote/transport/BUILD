load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "basic.go",
        "bearer.go",
        "doc.go",
        "error.go",
        "logger.go",
        "ping.go",
        "retry.go",
        "schemer.go",
        "scope.go",
        "transport.go",
        "useragent.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/remote/transport",
    importpath = "github.com/google/go-containerregistry/pkg/v1/remote/transport",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/docker/distribution/registry/client/auth/challenge:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/redact:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/retry:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/authn:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
    ],
)
