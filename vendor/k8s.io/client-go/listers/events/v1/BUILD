load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "event.go",
        "expansion_generated.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/listers/events/v1",
    importpath = "k8s.io/client-go/listers/events/v1",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/api/events/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/api/errors:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/labels:go_default_library",
        "//vendor/k8s.io/client-go/tools/cache:go_default_library",
    ],
)
