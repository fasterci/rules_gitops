load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "cpuinfo.go",
        "cpuinfo_amd64.go",
        "cpuinfo_amd64.s",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/klauspost/compress/internal/cpuinfo",
    importpath = "github.com/klauspost/compress/internal/cpuinfo",
    visibility = ["//vendor/github.com/klauspost/compress:__subpackages__"],
)
