load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "it_sidecar_lib",
    srcs = ["it_sidecar.go"],
    importpath = "github.com/fasterci/rules_gitops/testing/it_sidecar",
    visibility = ["//visibility:private"],
    deps = [
        "//testing/it_sidecar/stern",
        "//vendor/k8s.io/api/core/v1:core",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:meta",
        "//vendor/k8s.io/client-go/informers",
        "//vendor/k8s.io/client-go/kubernetes",
        "//vendor/k8s.io/client-go/plugin/pkg/client/auth/gcp",
        "//vendor/k8s.io/client-go/rest",
        "//vendor/k8s.io/client-go/tools/cache",
        "//vendor/k8s.io/client-go/tools/clientcmd",
        "//vendor/k8s.io/client-go/tools/portforward",
        "//vendor/k8s.io/client-go/transport/spdy",
        "//vendor/k8s.io/client-go/util/homedir",
    ],
)

go_binary(
    name = "it_sidecar",
    embed = [":it_sidecar_lib"],
    visibility = ["//visibility:public"],
)
