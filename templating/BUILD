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
    name = "go_default_library",
    srcs = ["main.go"],
    importpath = "github.com/fasterci/rules_gitops/templating",
    visibility = ["//visibility:private"],
    deps = ["//templating/fasttemplate:go_default_library"],
)

go_binary(
    name = "fast_template_engine",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)
