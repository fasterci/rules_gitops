load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "encode.go",
        "hpack.go",
        "huffman.go",
        "static_table.go",
        "tables.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/net/http2/hpack",
    importpath = "golang.org/x/net/http2/hpack",
    visibility = ["//visibility:public"],
)
