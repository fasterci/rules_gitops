load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "errors.go",
        "path.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/util/validation/field",
    importpath = "k8s.io/apimachinery/pkg/util/validation/field",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/apimachinery/pkg/util/errors:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/sets:go_default_library",
    ],
)
