#!/usr/bin/env bash
# Setup RISC-V cross-compiler using crossdev
# Run inside chroot after: ./12-emulation-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Installing crossdev..."
emerge --verbose sys-devel/crossdev

info "Creating crossdev overlay..."
mkdir -p /var/db/repos/crossdev/{profiles,metadata}
echo 'crossdev' > /var/db/repos/crossdev/profiles/repo_name
cat > /var/db/repos/crossdev/metadata/layout.conf << 'EOF'
masters = gentoo
thin-manifests = true
EOF

# Register crossdev overlay with portage
if [[ ! -f /etc/portage/repos.conf/crossdev.conf ]]; then
    mkdir -p /etc/portage/repos.conf
    cat > /etc/portage/repos.conf/crossdev.conf << 'EOF'
[crossdev]
location = /var/db/repos/crossdev
priority = 10
masters = gentoo
auto-sync = no
EOF
fi

info "Building RISC-V 64-bit bare-metal cross-compiler (elf)..."
echo "This may take a while as it compiles binutils, gcc, and newlib..."
crossdev --stable --target riscv64-unknown-elf

info "Building RISC-V 64-bit Linux cross-compiler (glibc)..."
echo "This will take longer as it includes glibc..."
crossdev --stable --target riscv64-unknown-linux-gnu

success "RISC-V cross-compilers installed!"
echo ""
echo "Available cross-compilers:"
echo ""
echo "Bare-metal (for embedded/firmware):"
echo "  riscv64-unknown-elf-gcc --version"
echo "  riscv64-unknown-elf-objdump -d program.o"
echo ""
echo "Linux (for user-space programs):"
echo "  riscv64-unknown-linux-gnu-gcc --version"
echo "  riscv64-unknown-linux-gnu-gcc -o hello hello.c"
echo ""
echo "Cross-compile prefix paths:"
echo "  /usr/riscv64-unknown-elf/"
echo "  /usr/riscv64-unknown-linux-gnu/"
echo ""
echo "Next: Run ./14-gcc16-setup.sh"
