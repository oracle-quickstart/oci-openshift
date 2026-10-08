#!/bin/bash
set -euo pipefail

# Uploads the agent rootfs image to OCI Object Storage and creates a PAR URL.
#
# NOTE: For disconnected installs (is_disconnected_installation=true), this
# script is NOT needed — terraform handles rootfs upload and PAR creation via
# the boot_artifacts module. Set rootfs_file_path in your tfvars instead.
#
# This script is for debugging: re-upload the rootfs or mint a fresh PAR
# without re-running terraform. Run AFTER 'openshift-install agent create
# image'.
#
# The agent installer appends /agent.x86_64-rootfs.img to bootArtifactsBaseURL,
# so the object name is stripped from the PAR path before printing it. This
# matches what the boot_artifacts module emits.
#
# Usage:
#   ./upload-rootfs.sh [CLUSTER_NAME]
#
# Environment variables (required):
#   OCI_OS_NAMESPACE    - Object Storage namespace (tenancy name)
#
# Environment variables (optional):
#   OCI_ROOTFS_BUCKET   - bucket name (default: <CLUSTER_NAME>-boot-artifacts,
#                         matching the bucket the boot_artifacts module creates)
#   PAR_EXPIRY_DAYS     - PAR validity in days (default: 7)

CLUSTER_NAME="${1:-ocp-deployment}"
INSTALL_DIR="${HOME}/${CLUSTER_NAME}-agentBasedInstallation"
ROOTFS_OBJECT="agent.x86_64-rootfs.img"
ROOTFS_FILE="${INSTALL_DIR}/boot-artifacts/${ROOTFS_OBJECT}"

OCI_OS_NAMESPACE="${OCI_OS_NAMESPACE:?Set OCI_OS_NAMESPACE to your Object Storage namespace}"
OCI_ROOTFS_BUCKET="${OCI_ROOTFS_BUCKET:-${CLUSTER_NAME}-boot-artifacts}"
PAR_EXPIRY_DAYS="${PAR_EXPIRY_DAYS:-7}"

if [[ ! -f "${ROOTFS_FILE}" ]]; then
  echo "Error: rootfs not found at ${ROOTFS_FILE}"
  echo "Run 'openshift-install agent create image' first."
  exit 1
fi

echo "Uploading ${ROOTFS_FILE} to ${OCI_ROOTFS_BUCKET}..."
oci os object put \
  --bucket-name "${OCI_ROOTFS_BUCKET}" \
  --namespace "${OCI_OS_NAMESPACE}" \
  --name "${ROOTFS_OBJECT}" \
  --file "${ROOTFS_FILE}" \
  --force

echo ""
echo "Creating PAR (valid ${PAR_EXPIRY_DAYS} days)..."
FULL_PATH="$(oci os preauth-request create \
  --bucket-name "${OCI_ROOTFS_BUCKET}" \
  --namespace "${OCI_OS_NAMESPACE}" \
  --name "rootfs-par" \
  --object-name "${ROOTFS_OBJECT}" \
  --access-type ObjectRead \
  --time-expires "$(date -u -d "+${PAR_EXPIRY_DAYS} days" +%Y-%m-%dT%H:%M:%SZ)" \
  --query 'data."full-path"' --raw-output)"

echo ""
echo "Full PAR URL (direct download of the rootfs):"
echo "  ${FULL_PATH}"
echo ""
echo "bootArtifactsBaseURL for agent-config.yaml (object name stripped):"
echo "  ${FULL_PATH%/${ROOTFS_OBJECT}}"
