load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["pointer.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/go-openapi/jsonpointer",
    importpath = "github.com/go-openapi/jsonpointer",
    visibility = ["//visibility:public"],
    deps = ["//vendor/github.com/go-openapi/swag:go_default_library"],
)
