#!/usr/bin/env bash
# Install QEMU/KVM with RISC-V support
# Run inside chroot after: ./10-gaming-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Installing QEMU with multiple architecture targets..."
emerge --verbose \
    app-emulation/qemu \
    app-emulation/libvirt \
    net-misc/bridge-utils \
    net-dns/dnsmasq

info "Installing virt-manager GUI..."
emerge --verbose \
    app-emulation/virt-manager

info "Configuring libvirt..."

# Enable libvirtd service
rc-update add libvirtd default

# Configure libvirt to use QEMU as non-root
mkdir -p /etc/libvirt/qemu
cat > /etc/libvirt/qemu.conf << 'EOF'
# Allow users in kvm and libvirt groups
user = "root"
group = "kvm"

# Security settings
security_driver = "none"
EOF

# Get username
read -rp "Enter username to configure for virtualization: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"

# Add user to virtualization groups
info "Adding ${USERNAME} to virtualization groups..."
usermod -aG kvm,libvirt "$USERNAME"

info "Creating default network configuration..."
cat > /etc/libvirt/qemu/networks/default.xml << 'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF

success "QEMU/KVM installed!"
echo ""
echo "QEMU targets installed:"
echo "  - x86_64 (system and user)"
echo "  - RISC-V 64-bit (system and user)"
echo "  - RISC-V 32-bit (system and user)"
echo ""
echo "After reboot, start libvirtd:"
echo "  rc-service libvirtd start"
echo "  virsh net-start default"
echo "  virsh net-autostart default"
echo ""
echo "Run a RISC-V VM:"
echo "  qemu-system-riscv64 -machine virt -nographic -m 2G \\"
echo "    -bios /usr/share/opensbi/lp64/generic/firmware/fw_jump.bin \\"
echo "    -kernel /path/to/Image -append 'console=ttyS0'"
echo ""
echo "Next: Run ./12-emulation-setup.sh"
