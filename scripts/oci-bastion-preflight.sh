#!/bin/bash
# oci-bastion-preflight.sh — verify bastion is ready for disconnected OCP install

errors=0

check() {
  if eval "$2" &>/dev/null; then
    echo "  PASS  $1"
  else
    echo "  FAIL  $1"
    ((errors++))
  fi
}

echo "Bastion preflight checks:"
check "tar installed"                "rpm -q tar"
check "openshift-install-fips on PATH" "command -v openshift-install-fips"
check "oc on PATH"                   "command -v oc"
check "terraform on PATH"            "command -v terraform"
check "SELinux enforcing"            "getenforce | grep -q Enforcing"
check "FIPS mode enabled"            "fips-mode-setup --check 2>&1 | grep -q enabled"

echo ""
if [ $errors -eq 0 ]; then
  echo "All checks passed."
else
  echo "$errors check(s) failed."
  exit 1
fi
