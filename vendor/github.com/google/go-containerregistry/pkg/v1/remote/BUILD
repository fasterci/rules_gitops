load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "catalog.go",
        "check.go",
        "delete.go",
        "descriptor.go",
        "doc.go",
        "fetcher.go",
        "image.go",
        "index.go",
        "layer.go",
        "list.go",
        "mount.go",
        "multi_write.go",
        "options.go",
        "progress.go",
        "puller.go",
        "pusher.go",
        "referrers.go",
        "schema1.go",
        "write.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/go-containerregistry/pkg/v1/remote",
    importpath = "github.com/google/go-containerregistry/pkg/v1/remote",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/google/go-containerregistry/internal/redact:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/retry:go_default_library",
        "//vendor/github.com/google/go-containerregistry/internal/verify:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/authn:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/logs:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/name:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/empty:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/mutate:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/partial:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/remote/transport:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/stream:go_default_library",
        "//vendor/github.com/google/go-containerregistry/pkg/v1/types:go_default_library",
        "//vendor/golang.org/x/sync/errgroup:go_default_library",
    ],
)
