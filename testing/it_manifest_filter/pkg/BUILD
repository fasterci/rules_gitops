load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "pkg",
    srcs = ["filter.go"],
    importpath = "github.com/fasterci/rules_gitops/testing/it_manifest_filter/pkg",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/ghodss/yaml",
        "//vendor/k8s.io/api/apps/v1:apps",
        "//vendor/k8s.io/api/core/v1:core",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1/unstructured",
        "//vendor/k8s.io/apimachinery/pkg/runtime",
        "//vendor/k8s.io/apimachinery/pkg/util/yaml",
        "//vendor/k8s.io/client-go/util/jsonpath",
    ],
)

go_test(
    name = "pkg_test",
    srcs = ["filter_test.go"],
    data = glob(["testdata/**"]),
    deps = [
        ":pkg",
        "//vendor/github.com/google/go-cmp/cmp",
    ],
)
