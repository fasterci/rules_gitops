#!/usr/bin/env bash
set -e

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

echo "Running create_gitops_prs in dry run mode..."
"./$PRER_BIN" \
  --workspace="$WORKSPACE_ROOT" \
  --git_repo="$WORKSPACE_ROOT" \
  --release_branch="gitops_test_release_branch" \
  --gitops_pr_into="main" \
  --target="//gitops/testing/..." \
  --dry_run \
  --dry_push
  
