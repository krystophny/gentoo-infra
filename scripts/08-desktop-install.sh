#!/usr/bin/env bash
# Install XFCE desktop with TTY autologin + startx
# Run inside chroot after: ./07-nvidia-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

ETC_DIR="${SCRIPT_DIR}/../etc"

# Prompt for username
read -rp "Enter username for autologin: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"

info "Installing X.org server..."
emerge --verbose \
    x11-base/xorg-server \
    x11-base/xorg-drivers \
    x11-apps/xinit \
    x11-apps/xrandr \
    x11-apps/xsetroot

info "Installing XFCE desktop..."
emerge --verbose \
    xfce-base/xfce4-meta \
    xfce-extra/xfce4-terminal \
    xfce-extra/xfce4-notifyd \
    xfce-extra/thunar-volman

info "Installing additional desktop utilities..."
emerge --verbose \
    media-fonts/dejavu \
    media-fonts/liberation-fonts \
    x11-misc/xdg-utils \
    x11-misc/xclip

# Create user if not exists
if ! id -u "$USERNAME" &>/dev/null; then
    info "Creating user ${USERNAME}..."
    useradd -m -G wheel,audio,video,input,plugdev -s /bin/bash "$USERNAME"
    echo ""
    warn "Set password for ${USERNAME}:"
    passwd "$USERNAME"
fi

# Add user to necessary groups
info "Adding ${USERNAME} to required groups..."
usermod -aG wheel,audio,video,input,plugdev "$USERNAME"

# Configure autologin in /etc/inittab
info "Configuring TTY autologin..."
if grep -q "^c1:" /etc/inittab; then
    sed -i "s|^c1:.*|c1:12345:respawn:/sbin/agetty --autologin ${USERNAME} 38400 tty1 linux|" /etc/inittab
else
    echo "c1:12345:respawn:/sbin/agetty --autologin ${USERNAME} 38400 tty1 linux" >> /etc/inittab
fi

# Create .xinitrc for user
USER_HOME="/home/${USERNAME}"
info "Creating .xinitrc for ${USERNAME}..."
cp "${ETC_DIR}/xinitrc" "${USER_HOME}/.xinitrc"
chmod +x "${USER_HOME}/.xinitrc"
chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.xinitrc"

# Create .bash_profile for auto-startx
info "Configuring auto-startx in .bash_profile..."
cat > "${USER_HOME}/.bash_profile" << 'EOF'
# ~/.bash_profile

# Source .bashrc
[[ -f ~/.bashrc ]] && source ~/.bashrc

# Auto-start X on tty1 login
if [[ -z "$DISPLAY" && "$(tty)" = "/dev/tty1" ]]; then
    exec startx
fi
EOF
chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.bash_profile"

# Enable elogind for session management
info "Enabling elogind service..."
rc-update add elogind boot

# Enable dbus
info "Enabling dbus service..."
rc-update add dbus default

success "XFCE desktop installed!"
echo ""
echo "After reboot, ${USERNAME} will auto-login on TTY1 and startx will launch XFCE."
echo ""
echo "Next: Run ./09-audio-setup.sh"
