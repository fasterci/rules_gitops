load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "certificatesigningrequest.go",
        "interface.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/informers/certificates/v1beta1",
    importpath = "k8s.io/client-go/informers/certificates/v1beta1",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/api/certificates/v1beta1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/runtime:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/watch:go_default_library",
        "//vendor/k8s.io/client-go/informers/internalinterfaces:go_default_library",
        "//vendor/k8s.io/client-go/kubernetes:go_default_library",
        "//vendor/k8s.io/client-go/listers/certificates/v1beta1:go_default_library",
        "//vendor/k8s.io/client-go/tools/cache:go_default_library",
    ],
)
