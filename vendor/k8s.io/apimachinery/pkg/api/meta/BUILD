load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "conditions.go",
        "doc.go",
        "errors.go",
        "firsthit_restmapper.go",
        "help.go",
        "interfaces.go",
        "lazy.go",
        "meta.go",
        "multirestmapper.go",
        "priority.go",
        "restmapper.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/apimachinery/pkg/api/meta",
    importpath = "k8s.io/apimachinery/pkg/api/meta",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/conversion:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime/schema:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/types:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/errors:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/sets:go_default_library",
        "//vendor/k8s.io/klog/v2:go_default_library",
    ],
)
