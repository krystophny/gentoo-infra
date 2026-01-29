#!/usr/bin/env bash
# Install Steam, Proton, and GameMode
# Run inside chroot after: ./09-audio-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Verifying 32-bit support is enabled..."
grep -q "ABI_X86.*32" /etc/portage/make.conf || \
    warn "32-bit support may not be enabled. Steam requires it."

info "Installing 32-bit NVIDIA libraries..."
emerge --verbose --noreplace \
    x11-drivers/nvidia-drivers

info "Installing Steam dependencies..."
emerge --verbose \
    games-util/steam-launcher \
    games-util/steam-meta

info "Installing GameMode (CPU governor tuning)..."
emerge --verbose \
    games-util/gamemode

info "Installing Vulkan tools for diagnostics..."
emerge --verbose \
    dev-util/vulkan-tools \
    media-libs/vulkan-loader

# Get username
read -rp "Enter username to configure for gaming: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"

# Add user to gaming-related groups
info "Adding ${USERNAME} to gaming groups..."
usermod -aG video,input "$USERNAME"

# Create gamemode group if not exists
if ! getent group gamemode &>/dev/null; then
    groupadd gamemode
fi
usermod -aG gamemode "$USERNAME"

# GameMode configuration
info "Creating GameMode configuration..."
mkdir -p /etc/gamemode.d
cat > /etc/gamemode.d/gamemode.ini << 'EOF'
[general]
renice=10
ioprio=0
softrealtime=on
inhibit_screensaver=1

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
nv_powermizer_mode=1

[custom]
# Add custom scripts here
start=
end=
EOF

success "Gaming stack installed!"
echo ""
echo "To run Steam:"
echo "  steam"
echo ""
echo "To run a game with GameMode:"
echo "  gamemoderun %command%"
echo "(Add 'gamemoderun %command%' to Steam launch options)"
echo ""
echo "Test GameMode:"
echo "  gamemoded -t"
echo ""
echo "Next: Run ./11-virt-setup.sh"
