# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

exports_files([
    "run-all.sh.tpl",
    "kubectl.sh.tpl",
    "nameprefix_deployment_labels_config.yaml",
    "namesuffix_deployment_labels_config.yaml",
])

sh_binary(
    name = "set_namespace",
    srcs = ["set_namespace.sh"],
    data = [
        "@kustomize_bin//:kustomize",
    ],
    # toolchains = ["@kustomize_toolchains//:resolved_toolchain"],
    # toolchains = ["//gitops/private:resolved_toolchain"],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
