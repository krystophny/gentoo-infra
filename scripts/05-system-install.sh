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

info "Installing development tools..."
emerge --verbose --noreplace \
    dev-lang/rust \
    dev-lang/go \
    sys-apps/ripgrep \
    sys-apps/fd \
    app-shells/fzf \
    sys-apps/bat \
    sys-process/htop \
    app-misc/tmux \
    net-misc/curl \
    app-misc/jq \
    app-text/tree

info "Installing build tools (cmake, meson, ninja, LLVM with flang+mlir)..."
emerge --verbose --noreplace \
    dev-build/cmake \
    dev-build/meson \
    dev-build/ninja \
    sys-devel/llvm \
    sys-devel/clang

info "Installing containers (podman)..."
emerge --verbose --noreplace \
    app-containers/podman \
    app-containers/crun

info "Installing micromamba..."
emerge --verbose --noreplace \
    dev-python/micromamba || {
    # If not in portage, install from binary
    warn "micromamba not in portage, installing from binary..."
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C /usr/local bin/micromamba
}

info "Installing git forge CLIs (GitHub, GitLab, Gitea)..."
emerge --verbose --noreplace \
    dev-util/github-cli \
    dev-util/glab || {
    # GitLab CLI might need manual install
    warn "Installing glab from binary..."
    curl -sL "https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_linux_amd64" -o /usr/local/bin/glab
    chmod +x /usr/local/bin/glab
}

# Gitea CLI (tea) - usually needs binary install
info "Installing tea (Gitea CLI)..."
emerge --verbose --noreplace dev-vcs/tea || {
    warn "Installing tea from binary..."
    curl -sL "https://dl.gitea.com/tea/main/tea-main-linux-amd64" -o /usr/local/bin/tea
    chmod +x /usr/local/bin/tea
}

# Detect and set CPU flags
info "Detecting CPU-specific flags..."
CPU_FLAGS=$(cpuid2cpuflags | cut -d: -f2)
echo "CPU_FLAGS_X86=\"${CPU_FLAGS}\"" >> /etc/portage/make.conf
echo ""
echo "Added to make.conf: CPU_FLAGS_X86=\"${CPU_FLAGS}\""

success "Base system installed!"
echo ""
echo "Next: Run ./06-kernel-build.sh"
