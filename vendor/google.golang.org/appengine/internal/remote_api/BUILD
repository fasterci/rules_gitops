load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["remote_api.pb.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/google.golang.org/appengine/internal/remote_api",
    importpath = "google.golang.org/appengine/internal/remote_api",
    visibility = ["//vendor/google.golang.org/appengine:__subpackages__"],
    deps = ["//vendor/github.com/golang/protobuf/proto:go_default_library"],
)
