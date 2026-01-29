# Gentoo Infrastructure

Complete infrastructure for bootstrapping an optimized Gentoo Linux system with:

- **Init**: OpenRC (no systemd)
- **Desktop**: XFCE with TTY autologin + startx (no display manager)
- **Graphics**: NVIDIA open kernel driver (nvidia-open)
- **Audio**: PipeWire with real-time scheduling
- **Gaming**: Steam, Proton, GameMode
- **Virtualization**: QEMU/KVM with RISC-V support
- **Emulation**: MAME for vintage systems
- **Cross-compile**: RISC-V toolchain via crossdev
- **Optimization**: Full LTO, Graphite, -march=native, -O3

## Quick Start

### 1. Create Bootable USB (from macOS/Linux host)

```bash
# Download and write Gentoo minimal install ISO
./scripts/00-create-usb.sh /dev/diskX
```

### 2. Boot from USB

Boot the target machine from the USB stick. At the shell prompt:

```bash
# Get network (usually automatic with DHCP)
dhcpcd

# Clone this repository
git clone https://github.com/krystophny/gentoo-infra.git
cd gentoo-infra
```

### 3. Partition and Install

```bash
# Partition target disk (e.g., /dev/nvme0n1)
./scripts/01-partition.sh /dev/nvme0n1

# Download and extract stage3
./scripts/02-stage3.sh

# Prepare chroot
./scripts/03-chroot-setup.sh
```

### 4. Enter Chroot and Continue

```bash
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
cd /root/gentoo-infra/scripts
```

### 5. Install System (inside chroot)

Run scripts in order:

```bash
./04-portage-config.sh    # Install make.conf, package.use, etc.
./05-system-install.sh    # Install base packages
./06-kernel-build.sh      # Build optimized kernel
./07-nvidia-setup.sh      # NVIDIA open driver
./08-desktop-install.sh   # XFCE + autologin
./09-audio-setup.sh       # PipeWire
./10-gaming-setup.sh      # Steam/Proton/GameMode
./11-virt-setup.sh        # QEMU/KVM + RISC-V
./12-emulation-setup.sh   # MAME
./13-crossdev-setup.sh    # RISC-V cross-compiler
./14-gcc16-setup.sh       # GCC 16 (optional)
./99-finalize.sh          # GRUB, fstab, services
```

### 6. Reboot

```bash
exit                      # Exit chroot
cd /
umount -R /mnt/gentoo
reboot
```

## Optimization Details

### Compiler Flags

All packages are built with aggressive optimizations (see `config/make.conf`):

```bash
COMMON_FLAGS="-march=native -mtune=native -O3 -pipe"
COMMON_FLAGS="${COMMON_FLAGS} -flto=auto -fuse-linker-plugin"
COMMON_FLAGS="${COMMON_FLAGS} -fgraphite-identity -floop-nest-optimize"
COMMON_FLAGS="${COMMON_FLAGS} -funroll-loops -ftree-vectorize"
```

### Package-Specific Overrides

Some packages require special handling:

| Category | Override | Reason |
|----------|----------|--------|
| glibc, grub, rust | No LTO | ABI stability |
| OpenSSL, GnuPG | No fast-math | IEEE compliance |
| Scientific libs | IEEE-compliant | Numerical accuracy |

See `config/package.env/` for details.

## Directory Structure

```
gentoo-infra/
├── config/
│   ├── make.conf                 # Portage main configuration
│   ├── package.use/              # Per-package USE flags
│   ├── package.env/              # Compiler overrides
│   ├── env/                      # Environment definitions
│   ├── grub/                     # GRUB configuration
│   └── kernel/                   # Kernel config fragment
├── scripts/
│   ├── 00-create-usb.sh          # Create bootable USB
│   ├── 01-partition.sh           # Partition disk
│   ├── 02-stage3.sh              # Download stage3
│   ├── 03-chroot-setup.sh        # Prepare chroot
│   ├── 04-portage-config.sh      # Install configs
│   ├── 05-system-install.sh      # Base system
│   ├── 06-kernel-build.sh        # Build kernel
│   ├── 07-nvidia-setup.sh        # NVIDIA driver
│   ├── 08-desktop-install.sh     # XFCE desktop
│   ├── 09-audio-setup.sh         # PipeWire
│   ├── 10-gaming-setup.sh        # Gaming stack
│   ├── 11-virt-setup.sh          # Virtualization
│   ├── 12-emulation-setup.sh     # MAME
│   ├── 13-crossdev-setup.sh      # Cross-compiler
│   ├── 14-gcc16-setup.sh         # GCC 16 snapshot
│   ├── 99-finalize.sh            # Bootloader, fstab
│   └── lib/common.sh             # Shared functions
└── etc/
    ├── inittab.autologin         # Autologin config
    ├── xinitrc                   # X startup
    └── modprobe.d/               # Kernel module config
```

## Post-Installation Verification

After reboot, verify the installation:

```bash
# NVIDIA driver
nvidia-smi

# Audio
wpctl status
pw-top

# Gaming
gamemoded -t
steam

# Virtualization
virsh list
qemu-system-riscv64 --version

# Cross-compiler
riscv64-unknown-elf-gcc --version
riscv64-unknown-linux-gnu-gcc --version

# MAME
mame -listfull | head
```

## Scientific Computing (Optional)

To add the full scientific stack later:

```bash
emerge -av \
    sci-libs/openblas \
    sci-libs/lapack \
    sci-libs/fftw \
    sys-cluster/openmpi \
    sci-libs/hdf5 \
    sci-libs/netcdf-c \
    sci-libs/netcdf-fortran \
    dev-python/numpy \
    dev-python/scipy
```

See `config/package.use/scientific.use` for USE flags.

## Troubleshooting

### Kernel Panic / No Boot

1. Boot from USB again
2. Mount partitions: `mount /dev/nvme0n1p2 /mnt/gentoo`
3. Chroot and rebuild kernel with `make menuconfig`

### NVIDIA Driver Not Loading

```bash
# Check kernel modules
lsmod | grep nvidia

# Check nouveau is blacklisted
cat /etc/modprobe.d/blacklist-nouveau.conf

# Rebuild NVIDIA modules
emerge --oneshot x11-drivers/nvidia-drivers
```

### No Audio

```bash
# Check PipeWire is running
systemctl --user status pipewire  # Note: this is OpenRC, use:
pgrep pipewire

# Start manually
pipewire &
wireplumber &
pipewire-pulse &
```

### Steam Won't Start

```bash
# Verify 32-bit libraries
ls /usr/lib32/

# Check Vulkan
vulkaninfo | head
```

## License

MIT License - See LICENSE file.
