load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "flags.go",
        "proto_legacy_disable.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/google.golang.org/protobuf/internal/flags",
    importpath = "google.golang.org/protobuf/internal/flags",
    visibility = ["//vendor/google.golang.org/protobuf:__subpackages__"],
)
