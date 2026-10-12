#!/bin/bash
set -euo pipefail

# Extracts agent-config.yaml, install-config.yaml, and OCI day-0 manifests
# from terraform outputs into the agent-based installer directory.
#
# Run AFTER terraform pass 1 (create_openshift_instances=false) and
# BEFORE 'openshift-install agent create image'.
#
# Usage:
#   ./generate-ocp-artifacts.sh [CLUSTER_NAME] [TERRAFORM_DIR]
#
# Defaults:
#   CLUSTER_NAME  = ocp-deployment
#   TERRAFORM_DIR = ../terraform-stacks/create-cluster  (relative to this script)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_NAME="${1:-ocp-deployment}"
TERRAFORM_DIR="${2:-${OCP_TERRAFORM_DIR:-${SCRIPT_DIR}/../terraform-stacks/create-cluster}}"

INSTALL_DIR="${HOME}/${CLUSTER_NAME}-agentBasedInstallation"
BACKUP_DIR="${INSTALL_DIR}-backup"

echo "Terraform dir: ${TERRAFORM_DIR}"
echo "Install dir:   ${INSTALL_DIR}"

cd "${TERRAFORM_DIR}"

rm -rf "${INSTALL_DIR}" "${BACKUP_DIR}"
mkdir -p "${INSTALL_DIR}/openshift"

terraform output -raw agent_config  > "${INSTALL_DIR}/agent-config.yaml"
terraform output -raw install_config > "${INSTALL_DIR}/install-config.yaml"

# Every one of these must be present. A partial set still produces a bootable
# ISO, but the cluster cannot converge, and the failure surfaces much later as
# nodes stuck NotReady rather than as an error here.
REQUIRED_MANIFESTS=(
  manifest_oci_ccm
  manifest_oci_csi
  manifest_oci_ccm_config
  manifest_oci_csi_config
  manifest_machineconfig_ccm
  manifest_machineconfig_csi
  manifest_machineconfig_device_path
  manifest_cluster_network
  manifest_machineconfig_eval_user_data
  manifest_machineconfig_bm_vlan_mtu
)

# Emitted only under some configurations. Skipped without error when null.
OPTIONAL_MANIFESTS=(
  manifest_image_tag_mirror_set
)

failed=()
written=0

extract_manifest() {
  local name="$1" requirement="$2"
  local dest="${INSTALL_DIR}/openshift/${name}.yaml"
  local tmp="${dest}.tmp"

  # Write to a temp file first: a redirect creates its target before the
  # command runs, so failing in place would leave a zero-byte manifest behind
  # and the ISO build would happily consume it.
  if ! terraform output -raw "${name}" > "${tmp}" 2>/dev/null; then
    rm -f "${tmp}"
    if [[ "${requirement}" == "required" ]]; then
      failed+=("${name} — terraform output missing or null")
    else
      echo "  skipped ${name} (not configured)"
    fi
    return
  fi

  if [[ ! -s "${tmp}" ]] || ! grep -q '^kind:' "${tmp}"; then
    rm -f "${tmp}"
    if [[ "${requirement}" == "required" ]]; then
      failed+=("${name} — empty, or not a Kubernetes manifest")
    else
      echo "  skipped ${name} (empty)"
    fi
    return
  fi

  mv "${tmp}" "${dest}"
  written=$((written + 1))
  echo "  wrote ${name}.yaml"
}

for m in "${REQUIRED_MANIFESTS[@]}"; do extract_manifest "${m}" required; done
for m in "${OPTIONAL_MANIFESTS[@]}"; do extract_manifest "${m}" optional; done

if (( ${#failed[@]} > 0 )); then
  {
    echo ""
    echo "ERROR: ${#failed[@]} required manifest(s) could not be extracted:"
    printf '  - %s\n' "${failed[@]}"
    echo ""
    echo "Do NOT run 'openshift-install agent create image'. An ISO built from a"
    echo "partial set boots, but the cluster will not converge:"
    echo "  - without manifest_cluster_network, the OVN masquerade subnet"
    echo "    collides with the OCI metadata service and CNI never starts"
    echo "  - without the CCM manifests, nodes keep the"
    echo "    node.cloudprovider.kubernetes.io/uninitialized taint"
    echo ""
    echo "Confirm terraform pass 1 applied cleanly, then re-run this script."
  } >&2
  exit 1
fi

on_disk=$(find "${INSTALL_DIR}/openshift" -maxdepth 1 -name '*.yaml' -type f | wc -l)
if (( on_disk != written )); then
  echo "ERROR: expected ${written} manifests in ${INSTALL_DIR}/openshift, found ${on_disk}." >&2
  exit 1
fi

cp -R "${INSTALL_DIR}" "${BACKUP_DIR}"

echo ""
echo "Extracted ${written} manifests (${#REQUIRED_MANIFESTS[@]} required)."
echo ""
echo "Done. Next steps:"
echo "  cd ${INSTALL_DIR}"
echo "  openshift-install agent create image --dir=."
echo "  # Then upload rootfs + ISO, run terraform pass 2"
echo ""
echo "Note: the agent installer splits multi-document YAML and numbers the"
echo "pieces, so /etc/assisted/extra-manifests on the node will contain many"
echo "more files than the ${written} written here. Counting files there is not a"
echo "reliable check; compare prefixes instead."
