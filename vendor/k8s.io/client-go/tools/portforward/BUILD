load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "doc.go",
        "portforward.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/tools/portforward",
    importpath = "k8s.io/client-go/tools/portforward",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/api/core/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/httpstream:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/runtime:go_default_library",
        "//vendor/k8s.io/utils/net:go_default_library",
    ],
)
