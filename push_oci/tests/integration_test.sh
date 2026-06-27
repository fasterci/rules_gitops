#!/bin/bash -x
#
# Integration test that runs the push_oci target against a local registry
# and verifies that the rules_oci image is present.
#

# Start the local in-memory registry on the default port 1338
${REGISTRY_BIN} &
registry_pid=$!
trap "kill -9 $registry_pid" EXIT

# Wait for registry to start up
sleep 1.5

# Run the push rule target (passed as the first argument)
$1

# Verify the image is pushed successfully using crane
${CRANE_BIN} validate -v --fast --remote localhost:1338/repo/oci_img:testtag
