load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "stern",
    srcs = [
        "container_state.go",
        "main.go",
        "tail.go",
        "watch.go",
    ],
    importpath = "github.com/fasterci/rules_gitops/testing/it_sidecar/stern",
    visibility = ["//visibility:public"],
    deps = [
        "@io_k8s_api//core/v1:core",
        "@io_k8s_apimachinery//pkg/apis/meta/v1:meta",
        "@io_k8s_apimachinery//pkg/labels",
        "@io_k8s_apimachinery//pkg/watch",
        "@io_k8s_client_go//kubernetes",
        "@io_k8s_client_go//kubernetes/typed/core/v1:core",
    ],
)

alias(
    name = "go_default_library",
    actual = ":stern",
    visibility = ["//visibility:public"],
)
