load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "client.go",
        "socks.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/net/internal/socks",
    importpath = "golang.org/x/net/internal/socks",
    visibility = ["//vendor/golang.org/x/net:__subpackages__"],
)
