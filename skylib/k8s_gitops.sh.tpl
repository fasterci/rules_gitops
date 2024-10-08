#!/usr/bin/env bash
# Copyright 2020 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
set -e
set -o nounset
set -o pipefail

DEPLOYMENT_ROOT=""
PERFORM_PUSH="1"
# parse command line parameters
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -r|--deployment_root|--deployment-root)
    DEPLOYMENT_ROOT="$2"
    shift # past argument
    shift # past value
    ;;
    --nopush)
    PERFORM_PUSH=""
    shift
    ;;
    *)    # unknown option
    echo Unsupported parameter $1
    exit 1
    ;;
  esac
done

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
    PYTHON_RUNFILES=${RUNFILES} "$@" &
    PIDS+=($!)
}

function waitpids() {
    # Wait for all of the subprocesses, failing the script if any of them failed.
    if [ "${#PIDS[@]}" != 0 ]; then
        for pid in ${PIDS[@]}; do
            wait ${pid} || return $?
        done
    fi
}

if [ "%{deployment_branch}" != "" -a "${DEPLOYMENT_ROOT}" != "" ] ; then
  TARGET_DIR=${DEPLOYMENT_ROOT}
else
  echo "--deployment-root or deployment_branch is not specified, using repo root"
  TARGET_DIR=$BUILD_WORKSPACE_DIRECTORY
fi

%{statements}
