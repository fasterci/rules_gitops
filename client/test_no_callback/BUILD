load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "test_no_callback",
    srcs = ["sidecar_client_test_no_callback.go"],
    importpath = "github.com/fasterci/rules_gitops/client/test_no_callback",
    visibility = ["//visibility:public"],
    deps = ["//client"],
)

alias(
    name = "go_default_library",
    actual = ":test_no_callback",
    visibility = ["//visibility:public"],
)
