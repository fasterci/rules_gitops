load("@io_bazel_rules_go//go:def.bzl", "go_library")
load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")
load("@rules_proto//proto:defs.bzl", "proto_library")

proto_library(
    name = "analysis_proto",
    srcs = ["analysis.proto"],
    visibility = ["//visibility:public"],
    deps = ["//gitops/blaze_query:build_proto"],
)

go_proto_library(
    name = "analysis_go_proto",
    importpath = "github.com/fasterci/rules_gitops/gitops/analysis",
    proto = ":analysis_proto",
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query:build_go_proto",
    ],
)

go_library(
    name = "analysis",
    srcs = ["analysis.pb.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/analysis",
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query",
        "//vendor/google.golang.org/protobuf/reflect/protoreflect",
        "//vendor/google.golang.org/protobuf/runtime/protoimpl",
    ],
)
