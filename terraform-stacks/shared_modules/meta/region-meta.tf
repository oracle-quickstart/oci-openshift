# fetch the metadata of regionInfo from IMDS
data "external" "instance_regionInfo" {
  program = ["bash", "-c", <<EOT
set -e
METADATA=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/regionInfo)
# Simple check if output starts with '{' to roughly verify JSON format.
# On non-OCI instances, the curl may return an error HTML page instead of JSON. In this case, the script with treat the region as non-restricted.
if [[ "$METADATA" == \{* ]]; then
  echo "$METADATA"
else
  # Return an error string if the response is invalid or empty
  echo "error"
fi
EOT
  ]
}

locals {
  region_metadata = try(data.external.instance_regionInfo.result, "error")
}
