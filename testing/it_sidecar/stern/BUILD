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
        "//vendor/k8s.io/api/core/v1:core",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:meta",
        "//vendor/k8s.io/apimachinery/pkg/labels",
        "//vendor/k8s.io/apimachinery/pkg/watch",
        "//vendor/k8s.io/client-go/kubernetes",
        "//vendor/k8s.io/client-go/kubernetes/typed/core/v1:core",
    ],
)
