#!/usr/bin/env bash
# Install GCC 16 snapshot as parallel slot (not default)
# Run inside chroot after: ./13-crossdev-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Checking for GCC 16 in Portage..."

# Check if GCC 16 is available
if equery list -po sys-devel/gcc | grep -q "gcc-16"; then
    info "GCC 16 found in Portage, installing..."
    emerge --verbose =sys-devel/gcc-16*
else
    warn "GCC 16 not yet in Portage."
    echo ""
    echo "Options:"
    echo "1. Wait for GCC 16 to be added to Portage"
    echo "2. Create a local ebuild from GCC snapshots"
    echo ""
    echo "To create a local ebuild manually:"
    echo ""
    echo "  # Create local overlay"
    echo "  mkdir -p /var/db/repos/local/{profiles,metadata,sys-devel/gcc}"
    echo "  echo 'local' > /var/db/repos/local/profiles/repo_name"
    echo "  echo 'masters = gentoo' > /var/db/repos/local/metadata/layout.conf"
    echo ""
    echo "  # Copy GCC ebuild template"
    echo "  cp /var/db/repos/gentoo/sys-devel/gcc/gcc-15*.ebuild \\"
    echo "     /var/db/repos/local/sys-devel/gcc/gcc-16.0.0_pre.ebuild"
    echo ""
    echo "  # Edit SRC_URI to point to:"
    echo "  # https://gcc.gnu.org/pub/gcc/snapshots/LATEST-16/"
    echo ""
    echo "  # Generate manifest"
    echo "  cd /var/db/repos/local/sys-devel/gcc"
    echo "  ebuild gcc-16.0.0_pre.ebuild manifest"
    echo ""
    echo "  # Install"
    echo "  emerge =sys-devel/gcc-16.0.0_pre"
    exit 0
fi

# Show available GCC versions
info "Available GCC versions:"
gcc-config -l

echo ""
success "GCC 16 installed in parallel slot!"
echo ""
echo "Usage:"
echo ""
echo "List versions:  gcc-config -l"
echo "Switch system:  gcc-config x86_64-pc-linux-gnu-16"
echo "Switch back:    gcc-config x86_64-pc-linux-gnu-15"
echo ""
echo "Use without switching system default:"
echo ""
echo "  export CC=/usr/lib/gcc/x86_64-pc-linux-gnu/16/gcc"
echo "  export CXX=/usr/lib/gcc/x86_64-pc-linux-gnu/16/g++"
echo "  export FC=/usr/lib/gcc/x86_64-pc-linux-gnu/16/gfortran"
echo ""
echo "Or with CMake:"
echo ""
echo "  cmake -DCMAKE_C_COMPILER=/usr/lib/gcc/x86_64-pc-linux-gnu/16/gcc \\"
echo "        -DCMAKE_CXX_COMPILER=/usr/lib/gcc/x86_64-pc-linux-gnu/16/g++ \\"
echo "        -DCMAKE_Fortran_COMPILER=/usr/lib/gcc/x86_64-pc-linux-gnu/16/gfortran .."
echo ""
echo "Next: Run ./99-finalize.sh"
