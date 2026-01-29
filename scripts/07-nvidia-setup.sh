#!/usr/bin/env bash
# Install NVIDIA open kernel driver
# Run inside chroot after: ./06-kernel-build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

ETC_DIR="${SCRIPT_DIR}/../etc"

info "Installing blacklist for nouveau..."
mkdir -p /etc/modprobe.d
cp "${ETC_DIR}/modprobe.d/blacklist-nouveau.conf" /etc/modprobe.d/

# Verify USE flags are set for nvidia-open
info "Verifying nvidia-drivers USE flags..."
grep -q "kernel-open" /etc/portage/package.use/nvidia.use || \
    die "nvidia-open USE flag not set. Check package.use/nvidia.use"

info "Installing NVIDIA drivers (kernel-open variant)..."
emerge --verbose x11-drivers/nvidia-drivers

info "Installing OpenGL/Vulkan libraries..."
emerge --verbose \
    media-libs/mesa \
    media-libs/vulkan-loader \
    dev-util/vulkan-tools

info "Selecting NVIDIA OpenGL implementation..."
eselect opengl set nvidia

# Create nvidia-persistenced service if not exists
if [[ ! -f /etc/init.d/nvidia-persistenced ]]; then
    info "Creating nvidia-persistenced service..."
    cat > /etc/init.d/nvidia-persistenced << 'EOF'
#!/sbin/openrc-run

command="/usr/bin/nvidia-persistenced"
command_args="--user root"
pidfile="/var/run/nvidia-persistenced/nvidia-persistenced.pid"

depend() {
    need localmount
}

start_pre() {
    checkpath -d /var/run/nvidia-persistenced
}
EOF
    chmod +x /etc/init.d/nvidia-persistenced
fi

info "Enabling nvidia-persistenced service..."
rc-update add nvidia-persistenced default

success "NVIDIA drivers installed!"
echo ""
echo "Verify after reboot with: nvidia-smi"
echo ""
echo "Next: Run ./08-desktop-install.sh"
