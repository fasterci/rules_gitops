load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["key.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/util/keyutil",
    importpath = "k8s.io/client-go/util/keyutil",
    visibility = ["//visibility:public"],
)
