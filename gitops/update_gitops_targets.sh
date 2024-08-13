#!/usr/bin/env bash
#
# Update the gitops targets in the repository.
# This script should be copied to your repository and updated to reflect the local configuration.
#
# CONFIGURATION:
RELEASE_BRANCH=main
TARGET="//..."

set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
q="attr(deployment_branch, \".+\", attr(release_branch_prefix, \"${RELEASE_BRANCH}\", kind(gitops, ${TARGET})))"

targets=$(bazel query ${q} --output label --noshow_progress)
#convert to ordered starlark array
targets=$(echo "${targets}" | sort | awk '{print "    \"" $0 "\","}')
echo "GITOPS_TARGETS_${RELEASE_BRANCH} = [
${targets}
]" > "${SCRIPT_DIR}/targets.bzl"

