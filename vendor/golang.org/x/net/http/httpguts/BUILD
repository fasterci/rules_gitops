load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "guts.go",
        "httplex.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/golang.org/x/net/http/httpguts",
    importpath = "golang.org/x/net/http/httpguts",
    visibility = ["//visibility:public"],
    deps = ["//vendor/golang.org/x/net/idna:go_default_library"],
)
