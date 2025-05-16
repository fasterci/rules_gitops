# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("@rules_go//go:def.bzl", "go_library")
load("@rules_go//proto:def.bzl", "go_proto_library")
load("@rules_proto//proto:defs.bzl", "proto_library")
load("//starlark:proto.bzl", "write_go_proto_srcs")

proto_library(
    name = "blaze_query_proto",
    srcs = ["build.proto"],
    visibility = ["//visibility:public"],
)

go_proto_library(
    name = "blaze_query_go_proto",
    gc_goopts = ["-trimpath=$(BINDIR)=>."],
    importpath = "github.com/fasterci/rules_gitops/gitops/blaze_query",
    proto = ":blaze_query_proto",
    visibility = ["//visibility:public"],
)

write_go_proto_srcs(
    name = "write_generated_protos",
    src = "build_query.pb.go",
    go_proto_library = ":blaze_query_go_proto",
    visibility = ["//visibility:public"],
)

go_library(
    name = "blaze_query",
    srcs = ["build.pb.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/blaze_query",
    visibility = ["//visibility:public"],
    deps = ["@com_github_golang_protobuf//proto"],
)

alias(
    name = "go_default_library",
    actual = ":blaze_query",
    visibility = ["//visibility:public"],
)
