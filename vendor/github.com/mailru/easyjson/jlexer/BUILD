load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "bytestostr.go",
        "error.go",
        "lexer.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/mailru/easyjson/jlexer",
    importpath = "github.com/mailru/easyjson/jlexer",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/josharian/intern:go_default_library"],
)
