load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "allocationresult.go",
        "podscheduling.go",
        "podschedulingspec.go",
        "podschedulingstatus.go",
        "resourceclaim.go",
        "resourceclaimconsumerreference.go",
        "resourceclaimparametersreference.go",
        "resourceclaimschedulingstatus.go",
        "resourceclaimspec.go",
        "resourceclaimstatus.go",
        "resourceclaimtemplate.go",
        "resourceclaimtemplatespec.go",
        "resourceclass.go",
        "resourceclassparametersreference.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/k8s.io/client-go/applyconfigurations/resource/v1alpha1",
    importpath = "k8s.io/client-go/applyconfigurations/resource/v1alpha1",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/k8s.io/api/resource/v1alpha1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/apis/meta/v1:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/types:go_default_library",
        "//vendor/k8s.io/apimachinery/pkg/util/managedfields:go_default_library",
        "//vendor/k8s.io/client-go/applyconfigurations/core/v1:go_default_library",
        "//vendor/k8s.io/client-go/applyconfigurations/internal:go_default_library",
        "//vendor/k8s.io/client-go/applyconfigurations/meta/v1:go_default_library",
    ],
)
