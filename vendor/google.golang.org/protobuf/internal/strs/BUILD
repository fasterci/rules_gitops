load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "strings.go",
        "strings_pure.go",
        "strings_unsafe.go",
    ],
    importmap = "github.com/fasterci/rules_gitops/vendor/google.golang.org/protobuf/internal/strs",
    importpath = "google.golang.org/protobuf/internal/strs",
    visibility = ["//vendor/google.golang.org/protobuf:__subpackages__"],
    deps = [
        "//vendor/google.golang.org/protobuf/internal/flags:go_default_library",
        "//vendor/google.golang.org/protobuf/reflect/protoreflect:go_default_library",
    ],
)
