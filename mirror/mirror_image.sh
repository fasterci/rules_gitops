#!/bin/bash
set -eu

function guess_runfiles() {
    if [ -d ${BASH_SOURCE[0]}.runfiles ]; then
        echo "$( cd ${BASH_SOURCE[0]}.runfiles && pwd )"
    else
        mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
        echo $mydir | sed -e 's|\(.*\.runfiles\)/.*|\1|'
    fi
}

RUNFILES="${PYTHON_RUNFILES:-$(guess_runfiles)}"

{mirror_tool} -from {src_image} -digest {digest} -to {dst_image} -timeout {timeout}
