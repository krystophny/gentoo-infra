#!/usr/bin/env bash
# Install portage configuration (make.conf, package.use, etc.)
# Run inside chroot after: ./03-chroot-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

CONFIG_DIR="${SCRIPT_DIR}/../config"

info "Installing make.conf..."
cp "${CONFIG_DIR}/make.conf" /etc/portage/make.conf

info "Installing package.use files..."
mkdir -p /etc/portage/package.use
for f in "${CONFIG_DIR}/package.use"/*; do
    [[ -f "$f" ]] && cp "$f" /etc/portage/package.use/
done

info "Installing package.env files..."
mkdir -p /etc/portage/package.env
for f in "${CONFIG_DIR}/package.env"/*; do
    [[ -f "$f" ]] && cp "$f" /etc/portage/package.env/
done

info "Installing env directory..."
mkdir -p /etc/portage/env
for f in "${CONFIG_DIR}/env"/*; do
    [[ -f "$f" ]] && cp "$f" /etc/portage/env/
done

info "Installing package.accept_keywords..."
mkdir -p /etc/portage/package.accept_keywords
for f in "${CONFIG_DIR}/package.accept_keywords"/*; do
    [[ -f "$f" ]] && cp "$f" /etc/portage/package.accept_keywords/
done

info "Installing GRUB config..."
mkdir -p /etc/default
cp "${CONFIG_DIR}/grub/grub" /etc/default/grub

info "Syncing Portage tree..."
emerge-webrsync

info "Updating Portage itself..."
emerge --oneshot sys-apps/portage

success "Portage configured!"
echo ""
echo "Verify settings with: emerge --info"
echo ""
echo "Next: Run ./05-system-install.sh"
