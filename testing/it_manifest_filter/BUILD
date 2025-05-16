load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "it_manifest_filter_lib",
    srcs = ["it_manifest_filter.go"],
    importpath = "github.com/fasterci/rules_gitops/testing/it_manifest_filter",
    visibility = ["//visibility:private"],
    deps = ["//testing/it_manifest_filter/pkg"],
)

go_binary(
    name = "it_manifest_filter",
    embed = [":it_manifest_filter_lib"],
    visibility = ["//visibility:public"],
)
