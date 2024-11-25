#!/usr/bin/env bash
set -x
set -e

GIT_COMMIT=$(git rev-parse HEAD)

%{prer} --git_commit=$GIT_COMMIT %{params} "${@}"
