#!/bin/bash
set -euo pipefail

# Lists all running OCI compute instances in a compartment with name, IP, and OCID.
#
# Usage:
#   ./oci-list-vms.sh [COMPARTMENT_OCID]
#
# Or set COMPARTMENT_OCID as an environment variable.

COMPARTMENT_ID="${1:-${COMPARTMENT_OCID:?Set COMPARTMENT_OCID or pass it as an argument}}"

export OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING=True

instances=$(oci compute instance list --compartment-id "$COMPARTMENT_ID" --output json | jq -c '.data[] | select(."lifecycle-state" == "RUNNING") | {id: .id, name: ."display-name"}')

printf "%-30s %-16s %s\n" "VM_NAME" "PRIVATE_IP" "INSTANCE_ID"
echo "-----------------------------------------------------------------------------------------------------------"

echo "$instances" | while read -r instance; do
    if [ -n "$instance" ]; then
        id=$(echo "$instance" | jq -r '.id')
        name=$(echo "$instance" | jq -r '.name')
        private_ip=$(oci compute instance list-vnics --instance-id "$id" --query "data[0].\"private-ip\"" --raw-output)
        printf "%-30s %-16s %s\n" "$name" "$private_ip" "$id"
    fi
done
