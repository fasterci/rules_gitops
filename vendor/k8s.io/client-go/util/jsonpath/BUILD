load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "jsonpath.go",
        "node.go",
        "parser.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/util/jsonpath",
    importpath = "k8s.io/client-go/util/jsonpath",
    visibility = ["//visibility:public"],
    deps = ["//vendor/k8s.io/client-go/third_party/forked/golang/template:go_default_library"],
)
