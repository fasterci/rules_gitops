load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = ["any.pb.go"],
    importmap = "github.com/fasterci/rules_gitops/vendor/github.com/golang/protobuf/ptypes/any",
    importpath = "github.com/golang/protobuf/ptypes/any",
    visibility = ["//visibility:public"],
    deps = [
        "//vendor/google.golang.org/protobuf/reflect/protoreflect:go_default_library",
        "//vendor/google.golang.org/protobuf/runtime/protoimpl:go_default_library",
        "//vendor/google.golang.org/protobuf/types/known/anypb:go_default_library",
    ],
)
