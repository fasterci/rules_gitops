load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "it_sidecar_lib",
    srcs = ["it_sidecar.go"],
    importpath = "github.com/fasterci/rules_gitops/testing/it_sidecar",
    visibility = ["//visibility:private"],
    deps = [
        "//testing/it_sidecar/stern",
        "@io_k8s_api//core/v1:core",
        "@io_k8s_apimachinery//pkg/apis/meta/v1:meta",
        "@io_k8s_client_go//informers",
        "@io_k8s_client_go//kubernetes",
        "@io_k8s_client_go//plugin/pkg/client/auth/gcp",
        "@io_k8s_client_go//rest",
        "@io_k8s_client_go//tools/cache",
        "@io_k8s_client_go//tools/clientcmd",
        "@io_k8s_client_go//tools/portforward",
        "@io_k8s_client_go//transport/spdy",
        "@io_k8s_client_go//util/homedir",
    ],
)

go_binary(
    name = "it_sidecar",
    embed = [":it_sidecar_lib"],
    visibility = ["//visibility:public"],
)
