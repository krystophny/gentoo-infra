#!/usr/bin/env bash
# Prepare chroot environment
# Run after: ./02-stage3.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root

# Verify stage3 extracted
[[ -f "${INSTALL_MOUNT}/etc/gentoo-release" ]] || die "Stage3 not extracted. Run 02-stage3.sh first."

info "Copying DNS configuration..."
cp --dereference /etc/resolv.conf "${INSTALL_MOUNT}/etc/"

info "Mounting pseudo-filesystems..."

# Mount proc
mount --types proc /proc "${INSTALL_MOUNT}/proc"

# Mount sys
mount --rbind /sys "${INSTALL_MOUNT}/sys"
mount --make-rslave "${INSTALL_MOUNT}/sys"

# Mount dev
mount --rbind /dev "${INSTALL_MOUNT}/dev"
mount --make-rslave "${INSTALL_MOUNT}/dev"

# Mount run (for elogind/udev)
mount --bind /run "${INSTALL_MOUNT}/run"
mount --make-slave "${INSTALL_MOUNT}/run"

# Copy our repository into the chroot
info "Copying gentoo-infra repository..."
mkdir -p "${INSTALL_MOUNT}/root/gentoo-infra"
cp -r "${REPO_ROOT}"/* "${INSTALL_MOUNT}/root/gentoo-infra/"

success "Chroot environment ready!"
echo ""
echo "To enter chroot:"
echo "  chroot ${INSTALL_MOUNT} /bin/bash"
echo "  source /etc/profile"
echo "  export PS1=\"(chroot) \${PS1}\""
echo ""
echo "Inside chroot, run:"
echo "  cd /root/gentoo-infra/scripts"
echo "  ./04-portage-config.sh"
