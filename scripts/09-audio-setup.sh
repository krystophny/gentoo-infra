#!/usr/bin/env bash
# Install PipeWire audio stack
# Run inside chroot after: ./08-desktop-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Installing ALSA utilities..."
emerge --verbose \
    media-sound/alsa-utils \
    media-libs/alsa-lib

info "Installing PipeWire and WirePlumber..."
emerge --verbose \
    media-video/pipewire \
    media-video/wireplumber

info "Installing PulseAudio compatibility layer..."
emerge --verbose \
    media-libs/libpulse

info "Creating PipeWire user service configuration..."

# Get username from previous script
read -rp "Enter username for PipeWire setup: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"

USER_HOME="/home/${USERNAME}"
CONFIG_DIR="${USER_HOME}/.config"

mkdir -p "${CONFIG_DIR}/pipewire"
mkdir -p "${CONFIG_DIR}/wireplumber"

# Create autostart for PipeWire
mkdir -p "${CONFIG_DIR}/autostart"

cat > "${CONFIG_DIR}/autostart/pipewire.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=PipeWire
Exec=pipewire
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

cat > "${CONFIG_DIR}/autostart/pipewire-pulse.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=PipeWire PulseAudio
Exec=pipewire-pulse
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

cat > "${CONFIG_DIR}/autostart/wireplumber.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=WirePlumber
Exec=wireplumber
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

chown -R "${USERNAME}:${USERNAME}" "${CONFIG_DIR}"

# Add user to audio group
usermod -aG audio "$USERNAME"

info "Configuring real-time scheduling..."
# Create rtkit group and enable rtkit
emerge --verbose --noreplace sys-auth/rtkit

# Configure PAM limits for real-time audio
cat > /etc/security/limits.d/audio.conf << 'EOF'
@audio   -  rtprio     95
@audio   -  memlock    unlimited
@audio   -  nice       -19
EOF

success "PipeWire audio configured!"
echo ""
echo "After reboot, verify with:"
echo "  wpctl status"
echo "  pw-top"
echo ""
echo "Next: Run ./10-gaming-setup.sh"
