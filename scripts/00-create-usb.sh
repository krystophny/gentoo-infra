#!/usr/bin/env bash
# Create bootable Gentoo USB from macOS or Linux host
# Usage: ./00-create-usb.sh /dev/diskX

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

DEVICE="${1:-}"

if [[ -z "$DEVICE" ]]; then
    echo "Usage: $0 /dev/diskX"
    echo ""
    echo "Available disks:"
    if [[ "$(uname)" == "Darwin" ]]; then
        diskutil list external physical
    else
        lsblk -d -o NAME,SIZE,TYPE,MOUNTPOINT
    fi
    exit 1
fi

# Confirm device
warn "This will ERASE ALL DATA on ${DEVICE}"
confirm "Are you sure?" || exit 0

# Create working directory
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

info "Fetching latest minimal install ISO list..."
ISO_BASE="${GENTOO_RELEASES}/current-install-amd64-minimal"

# Find the latest ISO
ISO_NAME=$(wget -q -O - "${ISO_BASE}/" | grep -oP 'install-amd64-minimal-\d{8}T\d{6}Z\.iso' | head -1)

if [[ -z "$ISO_NAME" ]]; then
    # Alternative pattern
    ISO_NAME=$(wget -q -O - "${ISO_BASE}/" | grep -oE 'install-amd64-minimal-[0-9]+\.iso' | head -1)
fi

[[ -n "$ISO_NAME" ]] || die "Could not find ISO filename"

info "Latest ISO: ${ISO_NAME}"

# Download ISO and checksum
info "Downloading ISO..."
wget --show-progress "${ISO_BASE}/${ISO_NAME}" -O "${ISO_NAME}"

info "Downloading checksum..."
wget -q "${ISO_BASE}/${ISO_NAME}.sha256" -O "${ISO_NAME}.sha256"

info "Verifying checksum..."
sha256sum -c "${ISO_NAME}.sha256" || die "Checksum verification failed!"
success "Checksum verified"

# Write to USB
if [[ "$(uname)" == "Darwin" ]]; then
    info "Unmounting ${DEVICE}..."
    diskutil unmountDisk "$DEVICE" || true

    # Convert disk to raw device for faster write
    RAW_DEVICE="${DEVICE/disk/rdisk}"

    info "Writing ISO to ${RAW_DEVICE}..."
    sudo dd if="${ISO_NAME}" of="${RAW_DEVICE}" bs=8m status=progress
else
    info "Unmounting ${DEVICE}..."
    sudo umount "${DEVICE}"* 2>/dev/null || true

    info "Writing ISO to ${DEVICE}..."
    sudo dd if="${ISO_NAME}" of="${DEVICE}" bs=8M status=progress conv=fdatasync
fi

sync

success "Bootable USB created on ${DEVICE}"
info "You can now boot from this USB to install Gentoo"
