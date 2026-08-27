#!/bin/bash -x
#
# Integration test for cloudrun_deploy .apply and .delete targets using mock gcloud.
#

apply_bin=$1
delete_bin=$2
expected_image_ref=$3
expected_manifest_sub=$4
expected_project=$5
expected_region=$6

# Start the local in-memory registry on the default port 1338
${REGISTRY_BIN} &
registry_pid=$!
trap "kill -9 $registry_pid 2>/dev/null" EXIT

# Wait for registry to start up
for i in {1..50}; do
  if curl -s -f http://localhost:1338/v2/ >/dev/null; then
    break
  fi
  sleep 0.05
done

# Create a temporary directory for the mock gcloud and manifest dump
tmp_dir=$(mktemp -d)
trap "rm -rf $tmp_dir; kill -9 $registry_pid 2>/dev/null" EXIT

manifest_out="${tmp_dir}/applied_manifest.yaml"
gcloud_log="${tmp_dir}/gcloud.log"
mock_gcloud="${tmp_dir}/gcloud"

cat <<EOF > "${mock_gcloud}"
#!/bin/bash
echo "gcloud \$@" >> "${gcloud_log}"
has_replace=false
for arg in "\$@"; do
  if [ "\$arg" = "replace" ]; then
    has_replace=true
  fi
done

if [ "\$has_replace" = true ]; then
  cat > "${manifest_out}"
fi
EOF

chmod +x "${mock_gcloud}"

# Prepend mock gcloud to PATH
export PATH="${tmp_dir}:${PATH}"

# 1. Execute the apply target executable
if ! ${apply_bin}; then
  echo "Error: Apply target failed"
  exit 1
fi

# Verify that the image is successfully pushed using crane
if ! ${CRANE_BIN} validate -v --fast --remote ${expected_image_ref}; then
  echo "Error: Crane validation failed"
  exit 1
fi

# Verify that the manifest was applied and has the expected image reference
if [ ! -f "${manifest_out}" ]; then
  echo "Error: Applied manifest file was not created by mock gcloud"
  exit 1
fi

cat "${manifest_out}"

if ! grep -q "${expected_manifest_sub}" "${manifest_out}"; then
  echo "Error: Applied manifest does not contain expected substring '${expected_manifest_sub}'"
  exit 1
fi

# Verify gcloud apply arguments
expected_apply_args="gcloud run services replace - --project=${expected_project} --region=${expected_region}"
if ! grep -Fq "${expected_apply_args}" "${gcloud_log}"; then
  echo "Error: gcloud was not called with the expected replace arguments: ${expected_apply_args}"
  echo "gcloud log contents:"
  cat "${gcloud_log}"
  exit 1
fi

num_replaces=$(grep -c "gcloud run services replace" "${gcloud_log}")
if [ "${num_replaces}" -ne 1 ]; then
  echo "Error: expected gcloud run services replace to be called exactly once, but it was called ${num_replaces} times"
  cat "${gcloud_log}"
  exit 1
fi

# 2. Execute the delete target executable
if ! ${delete_bin}; then
  echo "Error: Delete target failed"
  exit 1
fi

# Verify gcloud delete arguments
for service in "${@:7}"; do
  expected_delete_args="gcloud run services delete ${service} --project=${expected_project} --region=${expected_region}"
  if ! grep -Fq "${expected_delete_args}" "${gcloud_log}"; then
    echo "Error: gcloud was not called with the expected delete arguments: ${expected_delete_args}"
    echo "gcloud log contents:"
    cat "${gcloud_log}"
    exit 1
  fi
done

echo "Success!"
