#!/usr/bin/env bash
# Common functions for Gentoo installation scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

die() {
    error "$*"
    exit 1
}

# Check if running as root
require_root() {
    [[ $EUID -eq 0 ]] || die "This script must be run as root"
}

# Check if in chroot
in_chroot() {
    [[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]]
}

# Verify we are in chroot when required
require_chroot() {
    in_chroot || die "This script must be run inside chroot"
}

# Verify we are NOT in chroot when required
require_not_chroot() {
    ! in_chroot || die "This script must NOT be run inside chroot"
}

# Wait for user confirmation
confirm() {
    local prompt="${1:-Continue?}"
    read -rp "${prompt} [y/N] " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Get number of CPU cores
nproc_safe() {
    nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4
}

# Download with verification
download_verify() {
    local url="$1"
    local checksum_url="$2"
    local dest="$3"

    info "Downloading $(basename "$url")..."
    wget -q --show-progress "$url" -O "$dest"

    info "Downloading checksum..."
    wget -q "$checksum_url" -O "${dest}.sha256"

    info "Verifying checksum..."
    (cd "$(dirname "$dest")" && sha256sum -c "$(basename "${dest}.sha256")")
}

# Gentoo mirror URL
GENTOO_MIRROR="${GENTOO_MIRROR:-https://distfiles.gentoo.org}"
GENTOO_RELEASES="${GENTOO_MIRROR}/releases/amd64/autobuilds"

# Mount point for installation
INSTALL_MOUNT="${INSTALL_MOUNT:-/mnt/gentoo}"

# Repository root (relative to this script)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
