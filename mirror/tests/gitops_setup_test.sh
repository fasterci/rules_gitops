#!/bin/bash -x
#
# This test runs the script passed as the first argument and verifies the image is pushed to the registry
#
${REGISTRY_BIN}&
registry_pid=$!
trap "kill -9 $registry_pid" EXIT

#push original image to the registry
${PUSH_IMAGE}
#setup the enviroment to be reproducible
K8S_MYNAMESPACE=1
export K8S_MYNAMESPACE

#FIXME: generated .apply uses system kubectl so we need to fake it
kubectl_path=$(dirname ${KUBECTL})
export PATH=${kubectl_path}:${PATH}

export KUBERNETES_MASTER=https://127.0.0.1:6443

echo executing test setup script $1
bash -x $1
if [ $? -ne 0 ]; then
  echo "Test setup script failed"
  exit 1
fi
echo verifying image $2
${CRANE_BIN} validate -v --fast --remote $2
