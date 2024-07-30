load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "pkg",
    srcs = ["resolver.go"],
    importpath = "github.com/fasterci/rules_gitops/resolver/pkg",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/github.com/ghodss/yaml",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1/unstructured",
        "//vendor/k8s.io/apimachinery/pkg/util/yaml",
    ],
)

# TODO(KZ): this test uses private manifests

go_test(
    name = "pkg_test",
    srcs = ["resolver_test.go"],
    data = glob(["testdata/**"]),
    deps = [":pkg"],
)
