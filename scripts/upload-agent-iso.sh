#!/bin/bash
set -euo pipefail

# Uploads the agent ISO to OCI Object Storage and creates a PAR URL.
#
# NOTE: For disconnected installs (is_disconnected_installation=true), this
# script is NOT needed — terraform handles ISO upload and PAR creation via the
# boot_artifacts module. Set iso_file_path in your tfvars instead.
#
# This script is for connected installs where the boot_artifacts module is not
# used. Run AFTER 'openshift-install agent create image'.
# The PAR URL printed at the end is the value for openshift_image_source_uri
# in terraform pass 2.
#
# Usage:
#   ./upload-agent-iso.sh [CLUSTER_NAME]
#
# Environment variables (required):
#   OCI_OS_NAMESPACE  - Object Storage namespace (tenancy name)
#
# Environment variables (optional):
#   OCI_ISO_BUCKET    - bucket name (default: OpenShift_Deployment)
#   PAR_EXPIRY_DAYS   - PAR validity in days (default: 7)

CLUSTER_NAME="${1:-ocp-deployment}"
INSTALL_DIR="${HOME}/${CLUSTER_NAME}-agentBasedInstallation"
ISO_FILE="${INSTALL_DIR}/agent.x86_64.iso"

OCI_OS_NAMESPACE="${OCI_OS_NAMESPACE:?Set OCI_OS_NAMESPACE to your Object Storage namespace}"
OCI_ISO_BUCKET="${OCI_ISO_BUCKET:-OpenShift_Deployment}"
PAR_EXPIRY_DAYS="${PAR_EXPIRY_DAYS:-7}"

if [[ ! -f "${ISO_FILE}" ]]; then
  echo "Error: ISO not found at ${ISO_FILE}"
  echo "Run 'openshift-install agent create image' first."
  exit 1
fi

echo "Uploading ${ISO_FILE} to ${OCI_ISO_BUCKET}..."
oci os object put \
  --bucket-name "${OCI_ISO_BUCKET}" \
  --namespace "${OCI_OS_NAMESPACE}" \
  --name agent.x86_64.iso \
  --file "${ISO_FILE}" \
  --force

echo ""
echo "Creating PAR (valid ${PAR_EXPIRY_DAYS} days)..."
oci os preauth-request create \
  --bucket-name "${OCI_ISO_BUCKET}" \
  --namespace "${OCI_OS_NAMESPACE}" \
  --name "agent-iso-par" \
  --object-name agent.x86_64.iso \
  --access-type ObjectRead \
  --time-expires "$(date -u -d "+${PAR_EXPIRY_DAYS} days" +%Y-%m-%dT%H:%M:%SZ)"

echo ""
echo "Use the 'full-path' value above as openshift_image_source_uri in terraform pass 2."
