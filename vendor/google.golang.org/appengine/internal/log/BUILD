load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["log_service.pb.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/google.golang.org/appengine/internal/log",
    importpath = "google.golang.org/appengine/internal/log",
    visibility = ["//vendor/google.golang.org/appengine:__subpackages__"],
    deps = ["//vendor/github.com/golang/protobuf/proto:go_default_library"],
)
