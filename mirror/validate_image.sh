#!/bin/bash
REMOTE="{src_image}"
LOCAL="{dst_image}@{digest}"
echo "Validating images ${REMOTE} and ${LOCAL}"
{crane_tool} validate -v --fast --remote ${REMOTE}
if [ $? -eq 0 ]; then
  echo "Image ${REMOTE} exist"
  exit 0
fi

echo "Image ${REMOTE} does not exist, checking ${LOCAL}"

{crane_tool} validate -v --fast --remote ${LOCAL}
if [ $? -eq 0 ]; then
  echo "Image ${LOCAL} exist"
  exit 0
fi

echo "Image ${LOCAL} does not exist"
exit 1
