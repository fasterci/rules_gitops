load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "build.go",
        "estargz.go",
        "gzip.go",
        "testutil.go",
        "types.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/containerd/stargz-snapshotter/estargz",
    importpath = "github.com/containerd/stargz-snapshotter/estargz",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/containerd/stargz-snapshotter/estargz/errorutil:go_default_library",
        "//vendor/github.com/klauspost/compress/zstd:go_default_library",
        "//vendor/github.com/opencontainers/go-digest:go_default_library",
        "//vendor/github.com/vbatts/tar-split/archive/tar:go_default_library",
        "//vendor/golang.org/x/sync/errgroup:go_default_library",
    ],
)
