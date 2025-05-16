load("@rules_go//go:def.bzl", "go_library")
load("@rules_go//proto:def.bzl", "go_proto_library")
load("@rules_proto//proto:defs.bzl", "proto_library")
load("//starlark:proto.bzl", "write_go_proto_srcs")

proto_library(
    name = "analysis_proto",
    srcs = ["analysis.proto"],
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query:blaze_query_proto",
    ],
)

go_proto_library(
    name = "analysis_go_proto",
    gc_goopts = ["-trimpath=$(BINDIR)=>."],
    importpath = "github.com/fasterci/rules_gitops/gitops/analysis",
    proto = ":analysis_proto",
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query:blaze_query_go_proto",
    ],
)

write_go_proto_srcs(
    name = "write_generated_protos",
    src = "analysis.pb.go",
    go_proto_library = ":analysis_go_proto",
    visibility = ["//visibility:public"],
)

go_library(
    name = "analysis",
    srcs = ["analysis.pb.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/analysis",
    visibility = ["//visibility:public"],
    deps = [
        "//gitops/blaze_query",
        "@org_golang_google_protobuf//reflect/protoreflect",
        "@org_golang_google_protobuf//runtime/protoimpl",
    ],
)

alias(
    name = "go_default_library",
    actual = ":analysis",
    visibility = ["//visibility:public"],
)
