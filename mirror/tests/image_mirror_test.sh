#!/bin/bash -x
#
# This test runs the script passed as the first argument and verifies the image is pushed to the registry
#
${REGISTRY_BIN}&
registry_pid=$!
trap "kill -9 $registry_pid" EXIT

echo verifying image $REMOTE does not exist
${CRANE_BIN} validate -v --fast --remote $REMOTE
if [ $? -eq 0 ]; then
  echo "Image $REMOTE should not exist"
  exit 1
fi

echo verifying image $LOCAL does not exist
${CRANE_BIN} validate -v --fast --remote $LOCAL
if [ $? -eq 0 ]; then
  echo "Image $LOCAL should not exist"
  exit 1
fi

#test should fail before pushing the image (no src, no dst)
echo verifying mirror image validation fails
${IMAGE_MIRROR_VALIDATE_SRC}
if [ $? -eq 0 ]; then
  echo "Image verification should fail"
  exit 1
fi

echo pushing image $SRC_IMAGE
${PUSH_IMAGE}

echo verifying image $REMOTE exists
${CRANE_BIN} validate -v --fast --remote $REMOTE
if [ $? -ne 0 ]; then
  echo "Image $REMOTE should exist"
  exit 1
fi

echo verifying image $LOCAL does not exist
${CRANE_BIN} validate -v --fast --remote $LOCAL
if [ $? -eq 0 ]; then
  echo "Image $LOCAL should not exist"
  exit 1
fi

#test should succeed with src image only
echo verifying mirror image validation fails
${IMAGE_MIRROR_VALIDATE_SRC}
if [ $? -ne 0 ]; then
  echo "Image verification should succeed"
  exit 1
fi

echo running image mirror
${IMAGE_MIRROR}
if [ $? -ne 0 ]; then
  echo "Image mirroring should succeed"
  exit 1
fi

echo verifying image $LOCAL exists
${CRANE_BIN} validate -v --fast --remote $LOCAL
if [ $? -ne 0 ]; then
  echo "Image $LOCAL should exist"
  exit 1
fi

echo verifying image $REMOTE exists
${CRANE_BIN} validate -v --fast --remote $REMOTE
if [ $? -ne 0 ]; then
  echo "Image $REMOTE should exist"
  exit 1
fi

#test should succeed with src and dst images
echo verifying mirror image validation succeeds
${IMAGE_MIRROR_VALIDATE_SRC}
if [ $? -ne 0 ]; then
  echo "Image verification should succeed"
  exit 1
fi

echo removing image $REMOTE
${CRANE_BIN} delete $REMOTE || exit 1

echo verifying image $REMOTE does not exist
${CRANE_BIN} validate -v --fast --remote $REMOTE
if [ $? -eq 0 ]; then
  echo "Image $REMOTE should not exist"
  exit 1
fi

echo verifying image $LOCAL exists
${CRANE_BIN} validate -v --fast --remote $LOCAL
if [ $? -ne 0 ]; then
  echo "Image $LOCAL should exist"
  exit 1
fi

#test should succeed with dst image only
echo verifying mirror image validation succeeds
${IMAGE_MIRROR_VALIDATE_SRC}
if [ $? -ne 0 ]; then
  echo "Image verification should succeed"
  exit 1
fi


# exit 1