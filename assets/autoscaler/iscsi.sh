#!/usr/bin/env bash
# Add OCI bare-metal iSCSI boot kernel args to an RHCOS qcow2 image.

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <input.qcow2> [output.qcow2]"
  exit 1
fi

IN_IMG="$1"
OUT_IMG="${2:-${IN_IMG%.qcow2}-iscsi.qcow2}"
NBD_DEV="${NBD_DEV:-/dev/nbd0}"
MNT_DIR="${MNT_DIR:-/mnt/rhcos-img}"

for cmd in qemu-nbd blkid mount umount ostree modprobe; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd"
    exit 1
  }
done

if [[ $EUID -ne 0 ]]; then
  echo "Run as root, for example: sudo $0 <input.qcow2> [output.qcow2]"
  exit 1
fi

cleanup() {
  set +e
  mountpoint -q "$MNT_DIR/boot/efi" && umount "$MNT_DIR/boot/efi"
  mountpoint -q "$MNT_DIR/boot" && umount "$MNT_DIR/boot"
  mountpoint -q "$MNT_DIR" && umount "$MNT_DIR"
  qemu-nbd -d "$NBD_DEV" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Copying image to $OUT_IMG"
cp --reflink=auto "$IN_IMG" "$OUT_IMG"

modprobe nbd max_part=16
qemu-nbd -d "$NBD_DEV" >/dev/null 2>&1 || true
qemu-nbd --connect="$NBD_DEV" "$OUT_IMG"

for _ in {1..20}; do
  ls "${NBD_DEV}"p* >/dev/null 2>&1 && break
  sleep 0.5
done

ROOT_PART="$(blkid "${NBD_DEV}"p* | awk -F: '/PARTLABEL="root"|LABEL="root"/ {print $1; exit}')"
BOOT_PART="$(blkid "${NBD_DEV}"p* | awk -F: '/PARTLABEL="boot"|LABEL="boot"/ {print $1; exit}')"
EFI_PART="$(blkid "${NBD_DEV}"p* | awk -F: '/PARTLABEL="EFI-SYSTEM"|LABEL="EFI-SYSTEM"|PARTLABEL="esp"|LABEL="esp"/ {print $1; exit}')"

[[ -n "$ROOT_PART" ]] || { echo "Could not find root partition"; exit 1; }
[[ -n "$BOOT_PART" ]] || { echo "Could not find boot partition"; exit 1; }

mkdir -p "$MNT_DIR"
mount "$ROOT_PART" "$MNT_DIR"
mkdir -p "$MNT_DIR/boot"
mount "$BOOT_PART" "$MNT_DIR/boot"

if [[ -n "${EFI_PART:-}" ]]; then
  mkdir -p "$MNT_DIR/boot/efi"
  mount "$EFI_PART" "$MNT_DIR/boot/efi"
fi

echo "Setting iSCSI kernel args in OSTree deployment"
if ! ostree admin --sysroot="$MNT_DIR" instutil set-kargs --merge \
  --append=rd.neednet=1 \
  --append=ip=ibft \
  --append=rd.iscsi=1 \
  --append=rd.iscsi.firmware=1 \
  --append=rd.iscsi.ibft=1 \
  --append=rd.net.timeout.dhcp=30 \
  --append=rd.net.timeout.carrier=30 \
  --append=ip=ens300f0np0:dhcp \
  --append=rd.iscsi.param=node.conn[0].timeo.noop_out_interval=30 \
  --append=rd.iscsi.param=node.conn[0].timeo.noop_out_timeout=60 \
  --append=rd.iscsi.param=node.session.timeo.replacement_timeout=120 \
  --append=rd.retry=10 \
  --append=rootwait \
  --append=rd.debug; then
  ostree admin --sysroot="$MNT_DIR" instutil set-kargs --merge \
    rd.neednet=1 ip=ibft rd.iscsi=1 rd.iscsi.firmware=1 rd.iscsi.ibft=1 \
    rd.net.timeout.dhcp=30 rd.net.timeout.carrier=30 ip=ens300f0np0:dhcp \
    'rd.iscsi.param=node.conn[0].timeo.noop_out_interval=30' \
    'rd.iscsi.param=node.conn[0].timeo.noop_out_timeout=60' \
    'rd.iscsi.param=node.session.timeo.replacement_timeout=120' \
    rd.retry=10 rootwait rd.debug
fi

echo "Verifying iSCSI kernel args"
grep -R --line-number 'rd.neednet=1' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'ip=ibft' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi=1' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi.firmware=1' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi.ibft=1' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.net.timeout.dhcp=30' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.net.timeout.carrier=30' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'ip=ens300f0np0:dhcp' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi.param=node.conn\[0\].timeo.noop_out_interval=30' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi.param=node.conn\[0\].timeo.noop_out_timeout=60' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.iscsi.param=node.session.timeo.replacement_timeout=120' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.retry=10' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rootwait' "$MNT_DIR/boot/loader/entries"/*.conf
grep -R --line-number 'rd.debug' "$MNT_DIR/boot/loader/entries"/*.conf

sync
echo "Done: $OUT_IMG"
