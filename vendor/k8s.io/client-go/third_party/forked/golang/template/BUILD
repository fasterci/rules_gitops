load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "exec.go",
        "funcs.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/third_party/forked/golang/template",
    importpath = "k8s.io/client-go/third_party/forked/golang/template",
    visibility = ["//visibility:public"],
)
