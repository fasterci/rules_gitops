load("@rules_go//go:def.bzl", "go_library", "go_test")

go_library(
    name = "pkg",
    srcs = ["resolver.go"],
    importpath = "github.com/fasterci/rules_gitops/resolver/pkg",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_ghodss_yaml//:yaml",
        "@io_k8s_apimachinery//pkg/apis/meta/v1/unstructured",
        "@io_k8s_apimachinery//pkg/util/yaml",
    ],
)

alias(
    name = "go_default_library",
    actual = ":pkg",
    visibility = ["//visibility:public"],
)

go_test(
    name = "pkg_test",
    srcs = ["resolver_test.go"],
    data = glob(["testdata/**"]),
    deps = [":pkg"],
)
