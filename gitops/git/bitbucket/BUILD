# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("@io_bazel_rules_go//go:def.bzl", "go_library", "go_test")

licenses(["notice"])  # Apache 2.0

go_library(
    name = "go_default_library",
    srcs = ["bitbucket.go"],
    importpath = "github.com/fasterci/rules_gitops/gitops/git/bitbucket",
    visibility = ["//visibility:public"],
)

go_test(
    name = "go_default_test",
    srcs = ["bitbucket_test.go"],
    data = glob(["testdata/**"]),
    embed = [":go_default_library"],
)
