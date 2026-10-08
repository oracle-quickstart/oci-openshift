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

MANIFESTS=(
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

for m in "${MANIFESTS[@]}"; do
  terraform output -raw "$m" > "${INSTALL_DIR}/openshift/${m}.yaml"
  echo "  wrote ${m}.yaml"
done

cp -R "${INSTALL_DIR}" "${BACKUP_DIR}"

echo ""
echo "Done. Next steps:"
echo "  cd ${INSTALL_DIR}"
echo "  openshift-install agent create image --dir=."
echo "  # Then upload rootfs + ISO, run terraform pass 2"
