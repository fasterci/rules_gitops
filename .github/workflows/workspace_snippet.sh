#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# Set by GH actions, see
# https://docs.github.com/en/actions/learn-github-actions/environment-variables#default-environment-variables
TAG=${GITHUB_REF_NAME}
# The prefix is chosen to match what GitHub generates for source archives
PREFIX="rules_gitops-${TAG:1}"
ARCHIVE="rules_gitops-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

set -o errexit -o nounset -o pipefail

TAG=${GITHUB_REF_NAME}
PREFIX="rules_gitops-${TAG:1}"
SHA=$(git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip | shasum -a 256 | awk '{print $1}')

cat << EOF
## Using bzlmod with Bazel 6 or later:
1. Add \`common --enable_bzlmod\` to \`.bazelrc\`.

2. Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_gitops", version = "${TAG:1}")
git_override(
    module_name = "rules_gitops",
    commit = "${GITHUB_SHA}",
    remote = "https://github.com/fasterci/rules_gitops",
)

kustomize = use_extension("@rules_gitops//gitops:extensions.bzl", "kustomize")
kustomize.kustomize_toolchain()
use_repo(kustomize, "kustomize_bin")
\`\`\`

## Using WORKSPACE:

`WORKSPACE` file is not supported in this version. The latest version with `WORKSPACE` support is [v0.32.13](https://github.com/fasterci/rules_gitops/releases/tag/v0.32.13)
EOF

