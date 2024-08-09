load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "execabs.go",
        "execabs_go118.go",
        "execabs_go119.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/sys/execabs",
    importpath = "golang.org/x/sys/execabs",
    visibility = ["//visibility:public"],
)
