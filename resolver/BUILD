load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "resolver_lib",
    srcs = ["resolver.go"],
    importpath = "github.com/fasterci/rules_gitops/resolver",
    visibility = ["//visibility:private"],
    deps = ["//resolver/pkg"],
)

go_binary(
    name = "resolver",
    embed = [":resolver_lib"],
    visibility = ["//visibility:public"],
)
