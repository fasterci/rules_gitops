load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "analysis",
    srcs = ["analysis.pb.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/analysis",
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query",
        "@com_github_golang_protobuf//proto",
    ],
)

alias(
    name = "go_default_library",
    actual = ":analysis",
    visibility = ["//visibility:public"],
)
