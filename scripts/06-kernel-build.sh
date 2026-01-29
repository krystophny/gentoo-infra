#!/usr/bin/env bash
# Build and install optimized kernel
# Run inside chroot after: ./05-system-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

CONFIG_DIR="${SCRIPT_DIR}/../config"
KERNEL_CONFIG="${CONFIG_DIR}/kernel/config"

# Find kernel source directory
KERNEL_SRC=$(ls -d /usr/src/linux-* 2>/dev/null | sort -V | tail -1)
[[ -d "$KERNEL_SRC" ]] || die "No kernel sources found. Install gentoo-sources first."

info "Using kernel sources: ${KERNEL_SRC}"

# Select kernel sources
eselect kernel set 1

cd /usr/src/linux

info "Generating default config..."
make defconfig

if [[ -f "$KERNEL_CONFIG" ]]; then
    info "Merging custom configuration..."
    cp "$KERNEL_CONFIG" /tmp/gentoo-kernel.config
    scripts/kconfig/merge_config.sh .config /tmp/gentoo-kernel.config
fi

# Allow user to review/modify config
echo ""
warn "Kernel configuration ready."
echo "You may want to run 'make menuconfig' for additional customization."
echo "Key settings to verify:"
echo "  - NVIDIA: DRM_NOUVEAU=n, DRM_SIMPLEDRM=n"
echo "  - KVM: CONFIG_KVM=m, CONFIG_KVM_INTEL=m or CONFIG_KVM_AMD=m"
echo "  - Filesystem: EXT4_FS=y, VFAT_FS=y"
echo ""
confirm "Continue with build?" || {
    echo "Run 'make menuconfig' in /usr/src/linux, then re-run this script."
    exit 0
}

NPROC=$(nproc_safe)

info "Building kernel (using ${NPROC} cores)..."
make KCFLAGS="-march=native -mtune=native" -j"${NPROC}"

info "Installing modules..."
make modules_install

info "Installing kernel..."
make install

# Copy kernel to /boot
KERNEL_VERSION=$(make -s kernelrelease)
cp arch/x86/boot/bzImage "/boot/vmlinuz-${KERNEL_VERSION}"
cp System.map "/boot/System.map-${KERNEL_VERSION}"
cp .config "/boot/config-${KERNEL_VERSION}"

success "Kernel ${KERNEL_VERSION} built and installed!"
echo ""
echo "Next: Run ./07-nvidia-setup.sh"
