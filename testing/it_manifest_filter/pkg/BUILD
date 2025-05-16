load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "pkg",
    srcs = ["filter.go"],
    importpath = "github.com/fasterci/rules_gitops/testing/it_manifest_filter/pkg",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_ghodss_yaml//:yaml",
        "@io_k8s_api//apps/v1:apps",
        "@io_k8s_api//core/v1:core",
        "@io_k8s_apimachinery//pkg/apis/meta/v1/unstructured",
        "@io_k8s_apimachinery//pkg/runtime",
        "@io_k8s_apimachinery//pkg/util/yaml",
        "@io_k8s_client_go//util/jsonpath",
    ],
)

alias(
    name = "go_default_library",
    actual = ":pkg",
    visibility = ["//visibility:public"],
)

go_test(
    name = "pkg_test",
    srcs = ["filter_test.go"],
    data = glob(["testdata/**"]),
    deps = [
        ":pkg",
        "@com_github_google_go_cmp//cmp",
    ],
)
