#!/usr/bin/env bash
# Copyright 2026 The rules_gitops Authors.
set -eu

function guess_runfiles() {
    if [ -d ${BASH_SOURCE[0]}.runfiles ]; then
        # Runfiles are adjacent to the current script.
        echo "$( cd ${BASH_SOURCE[0]}.runfiles && pwd )"
    else
        # The current script is within some other script's runfiles.
        mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        echo $mydir | sed -e 's|\(.*\.runfiles\)/.*|\1|'
    fi
}

RUNFILES="${PYTHON_RUNFILES:-$(guess_runfiles)}"

PIDS=()
function async() {
    # Launch the command asynchronously and track its process id.
    PYTHON_RUNFILES=${RUNFILES} RUNFILES_DIR=${RUNFILES} "$@" &
    PIDS+=($!)
}

function waitpids() {
    # Wait for all of the subprocesses, failing the script if any of them failed.
    if [ "${#PIDS[@]}" != 0 ]; then
        for pid in ${PIDS[@]}; do
            wait ${pid}
        done
    fi
}

PROJECT=%{project}
REGION=%{region}

%{statements}
