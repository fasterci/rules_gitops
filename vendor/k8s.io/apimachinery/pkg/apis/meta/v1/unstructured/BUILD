load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "helpers.go",
        "unstructured.go",
        "unstructured_list.go",
        "zz_generated.deepcopy.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/apis/meta/v1/unstructured",
    importpath = "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime/schema:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/types:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/json:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/runtime:go_default_library",
        "//vendor/k8s.io/klog/v2:go_default_library",
    ],
)
