# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

"""
GtiOps rules repositories initialization
"""

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies", "register_jq_toolchains")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
load("@rules_gitops//skylib/kustomize:kustomize.bzl", "download_kustomize", "kustomize_setup")
load("@rules_oci//oci:dependencies.bzl", "rules_oci_dependencies")
load("@rules_oci//oci:repositories.bzl", "LATEST_CRANE_VERSION", "oci_register_toolchains")
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
load("//gitops/private:kustomize_toolchain.bzl", "KUSTOMIZE_PLATFORMS", "kustomize_host_alias_repo", "kustomize_platform_repo", "kustomize_toolchains_repo", _DEFAULT_KUSTOMIZE_VERSION = "DEFAULT_KUSTOMIZE_VERSION")

DEFAULT_KUSTOMIZE_VERSION = _DEFAULT_KUSTOMIZE_VERSION

def rules_gitops_repositories():
    """Initializes Declares workspaces the GitOps rules depend on.

    Workspaces that use rules_gitops should call this after rules_gitops_dependencies call.
    """

    bazel_skylib_workspace()
    gazelle_dependencies()
    aspect_bazel_lib_dependencies(override_local_config_platform = True)
    register_jq_toolchains()
    rules_pkg_dependencies()
    kustomize_setup(name = "kustomize_bin")
    register_kustomize_toolchains(register = True)

    rules_oci_dependencies()
    oci_register_toolchains(
        name = "oci",
        crane_version = LATEST_CRANE_VERSION,
    )

DEFAULT_KUSTOMIZE_REPOSITORY = "kustomize"

def register_kustomize_toolchains(name = DEFAULT_KUSTOMIZE_REPOSITORY, version = DEFAULT_KUSTOMIZE_VERSION, register = True):
    """Registers kustomize toolchain and repositories

    Args:
        name: override the prefix for the generated toolchain repositories
        version: the version of kustomize to execute (see https://github.com/kubernetes-sigs/kustomize/releases)
        register: whether to call through to native.register_toolchains.
            Should be True for WORKSPACE users, but false when used under bzlmod extension
    """

    download_kustomize(name = "kustomize_bin")
    for [platform, meta] in KUSTOMIZE_PLATFORMS.items():
        kustomize_platform_repo(
            name = "%s_%s" % (name, platform),
            platform = platform,
            version = version,
        )
        if register:
            native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    kustomize_host_alias_repo(name = name)

    kustomize_toolchains_repo(
        name = "%s_toolchains" % name,
        user_repository_name = name,
    )
