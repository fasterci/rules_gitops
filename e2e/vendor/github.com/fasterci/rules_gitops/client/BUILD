load("@io_bazel_rules_go//go:def.bzl", "go_library")

exports_files(["noop.setup"])

go_library(
    name = "client",
    srcs = ["sidecar_client.go"],
    data = [
        ":noop.setup",
    ],
    importpath = "github.com/fasterci/rules_gitops/client",
    visibility = ["//visibility:public"],
)
