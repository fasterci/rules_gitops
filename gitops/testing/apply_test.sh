#!/bin/bash -x
#
# Integration test for k8s_deploy .apply target using mock kubectl.
#

apply_bin=$1
expected_image_ref=$2
expected_manifest_sub=$3

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

# Create a temporary directory for the mock kubectl and manifest dump
tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir; kill -9 $registry_pid" EXIT

manifest_out="${tmp_dir}/applied_manifest.yaml"
mock_kubectl="${tmp_dir}/kubectl"

cat <<EOF > "${mock_kubectl}"
#!/bin/bash
has_apply=false
for arg in "\$@"; do
  if [ "\$arg" = "apply" ]; then
    has_apply=true
  fi
done

if [ "\$has_apply" = true ]; then
  cat > "${manifest_out}"
else
  echo "mock kubectl: \$@"
fi
EOF

chmod +x "${mock_kubectl}"

# Prepend mock kubectl to PATH
export PATH="${tmp_dir}:${PATH}"

# Execute the apply target executable
export CLUSTER=testcluster
export USER=testuser

${apply_bin}

# 1. Verify that the image is successfully pushed using crane
${CRANE_BIN} validate -v --fast --remote ${expected_image_ref}

# 2. Verify that the manifest was applied and has the expected image reference
if [ ! -f "${manifest_out}" ]; then
  echo "Error: Applied manifest file was not created by mock kubectl"
  exit 1
fi

cat "${manifest_out}"

if ! grep -q "${expected_manifest_sub}" "${manifest_out}"; then
  echo "Error: Applied manifest does not contain expected substring '${expected_manifest_sub}'"
  exit 1
fi

echo "Success!"
