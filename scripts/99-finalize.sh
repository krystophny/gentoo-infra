#!/usr/bin/env bash
# Finalize installation: fstab, bootloader, services
# Run inside chroot as the LAST step

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

# Detect partitions from mounts
ROOT_PART=$(findmnt -n -o SOURCE /)
EFI_PART=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null || echo "")

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART" 2>/dev/null || echo "")
EFI_UUID=$(blkid -s UUID -o value "$EFI_PART" 2>/dev/null || echo "")

info "Detected partitions:"
echo "  Root: ${ROOT_PART} (UUID=${ROOT_UUID:-unknown})"
echo "  EFI:  ${EFI_PART:-none} (UUID=${EFI_UUID:-unknown})"

# Generate fstab
info "Generating /etc/fstab..."
cat > /etc/fstab << EOF
# /etc/fstab - Static file system information
# <fs>                                  <mountpoint>    <type>  <opts>          <dump/pass>

# Root partition
UUID=${ROOT_UUID}                       /               ext4    defaults,noatime 0 1

# EFI System Partition
UUID=${EFI_UUID}                        /boot/efi       vfat    defaults,noatime 0 2

# Pseudo filesystems
proc                                    /proc           proc    defaults         0 0
tmpfs                                   /tmp            tmpfs   defaults,nosuid,nodev 0 0
EOF

echo ""
cat /etc/fstab

# Set hostname
read -rp "Enter hostname: " HOSTNAME
[[ -n "$HOSTNAME" ]] || HOSTNAME="gentoo"
echo "$HOSTNAME" > /etc/hostname

# Configure hosts
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Set root password
info "Set root password:"
passwd root

# Install GRUB
info "Installing GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Gentoo

info "Generating GRUB configuration (zero timeout)..."
grub-mkconfig -o /boot/grub/grub.cfg

# Enable essential services
info "Enabling essential services..."
rc-update add dhcpcd default
rc-update add sshd default

# Clean up
info "Cleaning up..."
rm -rf /var/cache/distfiles/*
emerge --depclean

success "Installation complete!"
echo ""
echo "=========================================="
echo " Gentoo installation finalized!"
echo "=========================================="
echo ""
echo "Before rebooting:"
echo "  1. Exit chroot:    exit"
echo "  2. Unmount all:    cd / && umount -R /mnt/gentoo"
echo "  3. Reboot:         reboot"
echo ""
echo "After reboot:"
echo "  - Login will be automatic on TTY1"
echo "  - XFCE will start automatically"
echo "  - Verify NVIDIA:   nvidia-smi"
echo "  - Verify audio:    wpctl status"
echo "  - Test GameMode:   gamemoded -t"
echo "  - Test KVM:        virsh list"
echo ""
echo "Enjoy your optimized Gentoo system!"
