#!/usr/bin/env bash
# Install base system packages
# Run inside chroot after: ./04-portage-config.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

# Set timezone
info "Setting timezone to UTC (change in /etc/timezone)..."
echo "UTC" > /etc/timezone
emerge --config sys-libs/timezone-data

# Set locale
info "Configuring locales..."
cat > /etc/locale.gen << 'EOF'
en_US.UTF-8 UTF-8
EOF
locale-gen
eselect locale set en_US.utf8
env-update && source /etc/profile

info "Rebuilding @world with new USE flags (this will take a while)..."
emerge --update --deep --newuse @world

info "Installing essential system packages..."
emerge --verbose --noreplace \
    sys-kernel/linux-firmware \
    sys-kernel/gentoo-sources \
    sys-apps/pciutils \
    sys-apps/usbutils \
    net-misc/dhcpcd \
    net-misc/openssh \
    app-editors/vim \
    dev-vcs/git \
    sys-boot/grub \
    sys-boot/efibootmgr \
    app-portage/gentoolkit \
    app-portage/cpuid2cpuflags

# Detect and set CPU flags
info "Detecting CPU-specific flags..."
CPU_FLAGS=$(cpuid2cpuflags | cut -d: -f2)
echo "CPU_FLAGS_X86=\"${CPU_FLAGS}\"" >> /etc/portage/make.conf
echo ""
echo "Added to make.conf: CPU_FLAGS_X86=\"${CPU_FLAGS}\""

success "Base system installed!"
echo ""
echo "Next: Run ./06-kernel-build.sh"
