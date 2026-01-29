#!/usr/bin/env bash
# Download and extract Gentoo stage3 tarball (OpenRC, not systemd)
# Run after: ./01-partition.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

# Verify mount
[[ -d "${INSTALL_MOUNT}/boot/efi" ]] || die "${INSTALL_MOUNT} not mounted. Run 01-partition.sh first."

cd "${INSTALL_MOUNT}"

info "Fetching latest stage3 list..."
STAGE3_BASE="${GENTOO_RELEASES}/current-stage3-amd64-openrc"

# Find the latest stage3 tarball
STAGE3_NAME=$(wget -q -O - "${STAGE3_BASE}/" | grep -oP 'stage3-amd64-openrc-\d{8}T\d{6}Z\.tar\.xz' | head -1)

if [[ -z "$STAGE3_NAME" ]]; then
    # Alternative pattern without timestamp
    STAGE3_NAME=$(wget -q -O - "${STAGE3_BASE}/" | grep -oE 'stage3-amd64-openrc-[0-9]+\.tar\.xz' | head -1)
fi

[[ -n "$STAGE3_NAME" ]] || die "Could not find stage3 filename"

info "Latest stage3: ${STAGE3_NAME}"

# Download stage3 and checksum
info "Downloading stage3 tarball (~300 MiB)..."
wget --show-progress "${STAGE3_BASE}/${STAGE3_NAME}" -O "${STAGE3_NAME}"

info "Downloading checksum..."
wget -q "${STAGE3_BASE}/${STAGE3_NAME}.sha256" -O "${STAGE3_NAME}.sha256"

info "Verifying checksum..."
sha256sum -c "${STAGE3_NAME}.sha256" || die "Checksum verification failed!"
success "Checksum verified"

info "Extracting stage3 (this may take a while)..."
tar xpvf "${STAGE3_NAME}" --xattrs-include='*.*' --numeric-owner

# Clean up tarball
rm -f "${STAGE3_NAME}" "${STAGE3_NAME}.sha256"

success "Stage3 extracted to ${INSTALL_MOUNT}"
echo ""
echo "Next: Run ./03-chroot-setup.sh"
