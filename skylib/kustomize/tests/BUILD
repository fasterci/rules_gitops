# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

load("@bazel_tools//tools/build_rules:test_rules.bzl", "file_test")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("//push_oci:push_oci.bzl", "push_oci_rule")
load("//skylib/kustomize:kustomize.bzl", "gitops", "kubectl", "kustomize", "push_all")
load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")

# to generate new test data if needed:
# bazel run //skylib/kustomize:set_namespace newnamespace-1 <test.yaml >test_expected.yaml
sh_test(
    name = "set_namespace_test",
    size = "small",
    srcs = ["set_namespace_test.sh"],
    data = [
        "test.yaml",
        "test_expected.yaml",
        "//skylib/kustomize:set_namespace",
    ],
)

# Verify that rule is combining files without processing
kustomize(
    name = "raw_test",
    manifests = [
        "deployment.yaml",
        "service.yaml",
        "crb.yaml",
    ],
    namespace = "",
)

kustomize(
    name = "namespace_test",
    manifests = [
        "deployment.yaml",
        "service.yaml",
        "crb.yaml",
    ],
    namespace = "bs-dev",
)

file_test(
    name = "has_namespace",
    file = ":namespace_test",
    matches = 2,
    regexp = "namespace: bs-dev",
)

filegroup(
    name = "alltestfiles",
    srcs = [
        "crb.yaml",
        "deployment.yaml",
        "service.yaml",
    ],
)

kustomize(
    name = "raw2_test",
    manifests = [
        ":alltestfiles",
    ],
    namespace = "",
)

tar(
    name = "image_tar",
    srcs = [":container_content.txt"],
)

oci_image(
    name = "image",
    architecture = "amd64",
    os = "linux",
    tars = [":image_tar"],
    visibility = ["//visibility:public"],
)

push_oci_rule(
    name = "image_push",
    image = ":image",
    repository = "gcr.io/bs-dev/test_image",
    visibility = ["//visibility:public"],
)

kustomize(
    name = "image_test",
    images = [
        ":image_push",
    ],
    manifests = [
        "deployment.yaml",
        "service.yaml",
        "crb.yaml",
    ],
    namespace = "",
)

kustomize(
    name = "configmap_test",
    configmaps_srcs = glob(["configmaps/**/*"]),
    namespace = "",
)

kustomize(
    name = "secret_test",
    namespace = "",
    secrets_srcs = glob(["secrets/**/*"]),
)

kustomize(
    name = "integration_test",
    testonly = True,
    images = [
        ":image_push",
    ],
    manifests = [
        "deployment.yaml",
        "service.yaml",
        ":configmap_test",
    ],
    namespace = "{BUILD_USER}",
)

# bazel run //skylib/kustomize/tests:push_all
push_all(
    name = "push_all",
    testonly = True,
    srcs = [
        ":integration_test",
    ],
)

kubectl(
    name = "mynamespace.apply",
    testonly = True,
    srcs = [":integration_test"],
    cluster = "dev3",
    namespace = "test",
)

gitops(
    name = "dev-something.gitops",
    testonly = True,
    srcs = [":namespace_test"],
    cluster = "dev",
    namespace = "test",
)

#-------------------
kustomize(
    name = "name_prefix",
    manifests = ["test.yaml"],
    name_prefix = "prefix-",
    namespace = "",
)

#-------------------
kustomize(
    name = "name_suffix",
    manifests = ["test.yaml"],
    name_suffix = "-suffix",
    namespace = "",
)

#-------------------
# patch plus image
kustomize(
    name = "patch",
    images = [
        ":image_push",
    ],
    manifests = ["deployment.yaml"],
    namespace = "",
    patches = ["overlay/deployment.yaml"],
)

#-------------------
# prefix and suffix for deployments: legacy compatibility
kustomize(
    name = "deployment_prefix_compat",
    manifests = ["deployment_with_labels.yaml"],
    name_prefix = "prefix-",
    namespace = "",
)

kustomize(
    name = "deployment_suffix_compat",
    manifests = ["deployment_with_labels.yaml"],
    name_suffix = "-suffix",
    namespace = "",
)

#-------------------
# prefix and suffix for deployments
kustomize(
    name = "deployment_prefix",
    configurations = ["//skylib/kustomize:nameprefix_deployment_labels_config.yaml"],
    manifests = ["deployment_with_labels.yaml"],
    name_prefix = "prefix-",
    namespace = "",
)

kustomize(
    name = "deployment_suffix",
    configurations = ["//skylib/kustomize:namesuffix_deployment_labels_config.yaml"],
    manifests = ["deployment_with_labels.yaml"],
    name_suffix = "-suffix",
    namespace = "",
)

#-------------------
# common labels and common annotations
kustomize(
    name = "common_labels",
    common_annotations = {"ownerTeam": "apps"},
    common_labels = {"flavor": "canary"},
    manifests = [
        "deployment_with_labels.yaml",
        "service.yaml",
    ],
    namespace = "",
)

#-------------------
# patch images

kustomize(
    name = "patch_images",
    image_name_patches = {
        "busybox": "alpine",
        "debian": "ubuntu",
    },
    image_tag_patches = {
        "busybox": "3",
    },
    manifests = [
        "job.yaml",
    ],
)

write_source_files(
    name = "write_all",
    files = {
        "expected_raw_test.yaml": ":raw_test",
        "expected_raw2_test.yaml": ":raw2_test",
        "expected_image_resolved_test.yaml": ":image_test",
        "expected_configmap_test.yaml": ":configmap_test",
        "expected_secret_test.yaml": ":secret_test",
        "expected_patch_test.yaml": ":patch",
        "expected_name_prefix.yaml": ":name_prefix",
        "expected_name_suffix.yaml": ":name_suffix",
        "expected_deployment_prefix_compat.yaml": ":deployment_prefix_compat",
        "expected_deployment_suffix_compat.yaml": ":deployment_suffix_compat",
        "expected_deployment_prefix.yaml": ":deployment_prefix",
        "expected_deployment_suffix.yaml": ":deployment_suffix",
        "expected_common_labels.yaml": ":common_labels",
        "expected_job.yaml": ":patch_images",
    },
)
