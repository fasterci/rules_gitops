load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "api.go",
        "api_common.go",
        "app_id.go",
        "identity.go",
        "identity_vm.go",
        "internal.go",
        "main_common.go",
        "main_vm.go",
        "metadata.go",
        "net.go",
        "transaction.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/google.golang.org/appengine/internal",
    importpath = "google.golang.org/appengine/internal",
    visibility = ["//vendor/google.golang.org/appengine:__subpackages__"],
    deps = [
        "//vendor/github.com/golang/protobuf/proto:go_default_library",
        "//vendor/golang.org/x/net/context:go_default_library",
        "//vendor/google.golang.org/appengine/internal/base:go_default_library",
        "//vendor/google.golang.org/appengine/internal/datastore:go_default_library",
        "//vendor/google.golang.org/appengine/internal/log:go_default_library",
        "//vendor/google.golang.org/appengine/internal/remote_api:go_default_library",
    ],
)
