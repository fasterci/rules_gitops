# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

licenses(["notice"])  # Apache 2.0

go_library(
    name = "prer_lib",
    srcs = ["create_gitops_prs.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/prer",
    visibility = ["//visibility:private"],
    deps = [
        "//gitops/analysis",
        "//gitops/bazel",
        "//gitops/commitmsg",
        "//gitops/exec",
        "//gitops/git",
        "//gitops/git/bitbucket",
        "//gitops/git/github",
        "//gitops/git/gitlab",
        "//vendor/google.golang.org/protobuf/proto",
    ],
)

go_binary(
    name = "create_gitops_prs",
    embed = [":prer_lib"],
    visibility = ["//visibility:public"],
)
