#!/usr/bin/env bash
set -e
set -x

# Make sure we are running from the repository root
WORKSPACE_ROOT=$(git rev-parse --show-toplevel)
cd "$WORKSPACE_ROOT"
echo "Workspace root is $WORKSPACE_ROOT"

# Build the create_gitops_prs tool first to make sure it's up to date
bazel build //gitops/prer:create_gitops_prs

# Find the built binary
if [ -x "bazel-bin/gitops/prer/create_gitops_prs_/create_gitops_prs" ]; then
  PRER_BIN="bazel-bin/gitops/prer/create_gitops_prs_/create_gitops_prs"
elif [ -x "bazel-bin/gitops/prer/create_gitops_prs" ]; then
  PRER_BIN="bazel-bin/gitops/prer/create_gitops_prs"
else
  echo "create_gitops_prs binary not found or not executable"
  exit 1
fi

# Capture output
OUTPUT_FILE=$(mktemp)
trap 'rm -f "$OUTPUT_FILE"' EXIT

echo "Running create_gitops_prs in dry run mode..."
if ! "./$PRER_BIN" \
  --workspace="$WORKSPACE_ROOT" \
  --git_repo="$WORKSPACE_ROOT" \
  --release_branch="gitops_test_release_branch" \
  --gitops_pr_into="main" \
  --target="//gitops/testing/..." \
  --dry_run \
  --dry_push > "$OUTPUT_FILE" 2>&1; then
  echo "ERROR: create_gitops_prs failed with exit code $?. Output was:" >&2
  cat "$OUTPUT_FILE" >&2
  exit 1
fi

cat "$OUTPUT_FILE"

# Define expected gitops targets
EXPECTED_TARGETS=(
  "//gitops/testing:external_image_label.gitops"
  "//gitops/testing:img_label.gitops"
  "//gitops/testing:img_legacy_alias.gitops"
  "//gitops/testing:img_legacy_label.gitops"
  "//gitops/testing:img_legacy_renamed_alias.gitops"
  "//gitops/testing:label.gitops"
  "//gitops/testing:legacy_alias.gitops"
  "//gitops/testing:legacy_label.gitops"
  "//gitops/testing:legacy_renamed_alias.gitops"
)

# Define expected push binaries (relative paths under workspace bazel-out/.../bin)
EXPECTED_PUSH_BINARIES=(
  "gitops/testing/external_image_docker_io.push"
  "gitops/testing/push_skylib_kustomize_tests_image_docker_io.push.sh"
  "gitops/testing/pushed_image_docker_io.push"
  "gitops/testing/push_pushed_image.sh"
  "gitops/testing/skylib_kustomize_tests_img_image_docker_io.push"
  "gitops/testing/img_pushed_image"
  "gitops/testing/img_pushed_image_docker_io.push"
)

echo "Verifying gitops targets..."
for target in "${EXPECTED_TARGETS[@]}"; do
  if ! grep -q "target $target" "$OUTPUT_FILE"; then
    echo "ERROR: Expected gitops target '$target' not found in output" >&2
    exit 1
  fi
done

echo "Verifying push binaries..."
for push_bin in "${EXPECTED_PUSH_BINARIES[@]}"; do
  escaped_workspace=$(echo "$WORKSPACE_ROOT" | sed 's/\./\\./g')
  escaped_bin=$(echo "$push_bin" | sed 's/\./\\./g')
  pattern="Skipping execution of $escaped_workspace/bazel-out/[^/]+/bin/$escaped_bin in "
  if ! grep -Eq "$pattern" "$OUTPUT_FILE"; then
    echo "ERROR: Expected push binary '$push_bin' was not executed/skipped in output" >&2
    exit 1
  fi
done

echo "Verification successful!"

