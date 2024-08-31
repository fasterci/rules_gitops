#!/bin/bash
REMOTE="{src_image}"
LOCAL="{dst_image}@{digest}"
echo "Validating images $REMOTE and $LOCAL"
{crane_tool} validate -v --fast --remote $REMOTE || {crane_tool} validate -v --fast --remote $LOCAL || exit 1
