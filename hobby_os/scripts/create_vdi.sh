#!/usr/bin/env bash
set -euo pipefail

IMAGE_PATH="${1:-}"
VDI_PATH="${2:-hobby_os.vdi}"

if [[ -z "${IMAGE_PATH}" ]]; then
  echo "usage: create_vdi.sh <bootimage.bin> [output.vdi]" >&2
  exit 2
fi

if [[ ! -f "${IMAGE_PATH}" ]]; then
  echo "error: image not found: ${IMAGE_PATH}" >&2
  exit 2
fi

if ! command -v VBoxManage >/dev/null 2>&1; then
  echo "error: VBoxManage not found. Install VirtualBox first." >&2
  exit 2
fi

VBoxManage convertfromraw "${IMAGE_PATH}" "${VDI_PATH}" --format VDI

echo "Created ${VDI_PATH}"
