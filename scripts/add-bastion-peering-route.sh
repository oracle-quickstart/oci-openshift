#!/usr/bin/env bash
set -euo pipefail

# Adds the bastion VCN peering route to the cluster's private route table.
# Terraform recreates the route table on each apply, so this must be re-run
# after every 'terraform apply' that creates instances (pass 2).
#
# Usage:
#   ROUTE_TABLE_OCID=ocid1.routetable... LPG_OCID=ocid1.localpeeringgateway... ./add-bastion-peering-route.sh
#
# Environment variables (required):
#   ROUTE_TABLE_OCID  - OCID of the cluster's private route table
#   LPG_OCID          - OCID of the Local Peering Gateway on the cluster VCN side
#
# Environment variables (optional):
#   BASTION_VCN_CIDR  - CIDR of the bastion VCN (default: 10.41.0.0/16)

BASTION_VCN_CIDR="${BASTION_VCN_CIDR:-10.41.0.0/16}"
LPG_OCID="${LPG_OCID:?Set LPG_OCID to the Local Peering Gateway OCID}"
ROUTE_TABLE_OCID="${ROUTE_TABLE_OCID:?Set ROUTE_TABLE_OCID to the private route table OCID}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Fetching current route rules..."
oci network route-table get \
  --rt-id "$ROUTE_TABLE_OCID" \
  --query 'data."route-rules"' \
  > "$TMPDIR/current_rules.json"

if jq -e ".[] | select(.destination == \"$BASTION_VCN_CIDR\")" "$TMPDIR/current_rules.json" > /dev/null 2>&1; then
  echo "Bastion peering route ($BASTION_VCN_CIDR) already exists. Nothing to do."
  exit 0
fi

echo "Adding bastion peering route ($BASTION_VCN_CIDR -> LPG)..."
jq --arg dest "$BASTION_VCN_CIDR" --arg lpg "$LPG_OCID" \
  '. + [{"destination": $dest, "destination-type": "CIDR_BLOCK", "network-entity-id": $lpg}]' \
  "$TMPDIR/current_rules.json" > "$TMPDIR/updated_rules.json"

oci network route-table update \
  --rt-id "$ROUTE_TABLE_OCID" \
  --route-rules "file://$TMPDIR/updated_rules.json" \
  --force

echo "Route added successfully."
