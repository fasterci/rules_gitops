load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["writer.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/mailru/easyjson/jwriter",
    importpath = "github.com/mailru/easyjson/jwriter",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/mailru/easyjson/buffer:go_default_library"],
)
