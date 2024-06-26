# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("//gitops:defs.bzl", "external_image", "k8s_deploy", "k8s_test_setup")
load("//push_oci:push_oci.bzl", "push_oci")

licenses(["notice"])  # Apache 2.0

k8s_deploy(
    name = "legacy_alias",
    cluster = "testcluster",
    deployment_branch = "test1",
    gitops = 1,
    images = {
        "testimage": "//skylib/kustomize/tests:image",
    },
    manifests = [
        ":deployment_legacy.yaml",
    ],
    namespace = "ci",
    release_branch_prefix = "gitops_test_release_branch",
    visibility = ["//visibility:public"],
)

k8s_deploy(
    name = "legacy_label",
    cluster = "testcluster",
    deployment_branch = "test1",
    gitops = 1,
    images = [
        "//skylib/kustomize/tests:image",
    ],
    manifests = [
        ":deployment.yaml",
    ],
    namespace = "ci",
    release_branch_prefix = "gitops_test_release_branch",
    visibility = ["//visibility:public"],
)

k8s_deploy(
    name = "label",
    cluster = "testcluster",
    deployment_branch = "test1",
    gitops = 1,
    images = [
        "//skylib/kustomize/tests:image",
    ],
    manifests = [
        ":deployment.yaml",
    ],
    namespace = "ci",
    release_branch_prefix = "gitops_test_release_branch",
    visibility = ["//visibility:public"],
)

# using image from external repo
external_image(
    name = "external_image",
    digest = "sha:1234567890",
    image = "gcr.io/repo/someimage:thetag",
)

k8s_deploy(
    name = "external_image_label",
    cluster = "testcluster",
    deployment_branch = "test1",
    gitops = 1,
    images = [
        ":external_image",
    ],
    manifests = [
        ":deployment1.yaml",
    ],
    namespace = "ci",
    release_branch_prefix = "gitops_test_release_branch",
    visibility = ["//visibility:public"],
)

push_oci(
    name = "pushed_image",
    image = "//skylib/kustomize/tests:image",
    registry = "gcr.io",
    repository = "repo/imagethere",
    tag = "thetag",
)

k8s_deploy(
    name = "legacy_renamed_alias",
    cluster = "testcluster",
    deployment_branch = "test1",
    gitops = 1,
    images = {
        "testimage": ":pushed_image",
    },
    manifests = [
        ":deployment_legacy.yaml",
    ],
    namespace = "ci",
    release_branch_prefix = "gitops_test_release_branch",
    visibility = ["//visibility:public"],
)

k8s_test_setup(
    name = "legacy_renamed_alias_it.setup",
    cluster = "@k8s_test//:cluster",
    kubeconfig = "@k8s_test//:kubeconfig",
    kubectl = "@k8s_test//:kubectl",
    objects = [
        ":legacy_renamed_alias",
    ],
)

write_source_files(
    name = "write_all",
    files = {
        "legacy_alias_expected.yaml": ":legacy_alias",
        "legacy_label_expected.yaml": ":legacy_label",
        "external_image_label_expected.yaml": ":external_image_label",
        "legacy_renamed_alias_expected.yaml": ":legacy_renamed_alias",
    },
)
