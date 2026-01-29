#!/usr/bin/env bash
# Partition target disk for Gentoo installation (UEFI GPT)
# Usage: ./01-partition.sh /dev/nvme0n1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

DISK="${1:-}"

if [[ -z "$DISK" ]]; then
    echo "Usage: $0 /dev/nvme0n1"
    echo ""
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE,MODEL
    exit 1
fi

# Determine partition suffix (nvme uses p1, sda uses 1)
if [[ "$DISK" == *nvme* ]] || [[ "$DISK" == *mmcblk* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

PART_EFI="${PART_PREFIX}1"
PART_ROOT="${PART_PREFIX}2"

warn "This will ERASE ALL DATA on ${DISK}"
echo "Partition layout:"
echo "  ${PART_EFI} - 512 MiB EFI System Partition (FAT32)"
echo "  ${PART_ROOT} - Remaining space (ext4)"
echo ""
confirm "Continue?" || exit 0

# Unmount any existing partitions
info "Unmounting existing partitions..."
umount "${PART_PREFIX}"* 2>/dev/null || true

# Create GPT partition table
info "Creating GPT partition table..."
parted -s "$DISK" mklabel gpt

# Create EFI partition (512 MiB)
info "Creating EFI partition..."
parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# Create root partition (remaining space)
info "Creating root partition..."
parted -s "$DISK" mkpart "root" ext4 513MiB 100%

# Wait for kernel to recognize partitions
partprobe "$DISK"
sleep 2

# Format EFI partition
info "Formatting EFI partition (FAT32)..."
mkfs.fat -F32 -n EFI "${PART_EFI}"

# Format root partition
# Note: -O "^metadata_csum" for GRUB compatibility on some versions
info "Formatting root partition (ext4)..."
mkfs.ext4 -L root -O "^metadata_csum" "${PART_ROOT}"

# Mount partitions
info "Mounting partitions..."
mkdir -p "${INSTALL_MOUNT}"
mount "${PART_ROOT}" "${INSTALL_MOUNT}"
mkdir -p "${INSTALL_MOUNT}/boot/efi"
mount "${PART_EFI}" "${INSTALL_MOUNT}/boot/efi"

success "Partitioning complete!"
echo ""
echo "Mounted:"
echo "  ${PART_ROOT} -> ${INSTALL_MOUNT}"
echo "  ${PART_EFI}  -> ${INSTALL_MOUNT}/boot/efi"
echo ""
echo "Next: Run ./02-stage3.sh"
