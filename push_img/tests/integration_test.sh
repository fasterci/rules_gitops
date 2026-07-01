#!/bin/bash -x
#
# Integration test that runs the push_oci target against a local registry
# and verifies that the image is present.
#

export DOCKER_CONFIG="${TEST_TMPDIR}/.docker"
mkdir -p "${DOCKER_CONFIG}"


# Start the local in-memory registry on the default port 1338
${REGISTRY_BIN} &
registry_pid=$!
trap "kill -9 $registry_pid" EXIT

# Wait for registry to start up
for i in {1..50}; do
  if curl -s -f http://localhost:1338/v2/ >/dev/null; then
    break
  fi
  sleep 0.05
done

# Run the push rule target (passed as the first argument)
$1

# Verify the image is pushed successfully using crane
${CRANE_BIN} validate -v --fast --remote localhost:1338/repo/img:testtag

# Run the second push rule target (passed as the second argument) if provided
if [ -n "$2" ]; then
  $2
  # Verify the derived image is pushed successfully using crane
  ${CRANE_BIN} validate -v --fast --remote localhost:1338/repo/derived_img:testtag
fi

