load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "base.go",
        "display.go",
        "models.go",
        "operations.go",
        "reader.go",
        "writer.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/google/gnostic/jsonschema",
    importpath = "github.com/google/gnostic/jsonschema",
    visibility = ["//visibility:public"],
    deps = ["//vendor/gopkg.in/yaml.v3:go_default_library"],
)
