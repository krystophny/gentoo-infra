# Gentoo Infrastructure - AI Instructions

## Project Overview

This repository contains infrastructure scripts and configuration for bootstrapping an optimized Gentoo Linux system with NVIDIA graphics, XFCE desktop, and development tools.

## Key Files

- `config/make.conf` - Main portage configuration with LTO/Graphite optimizations
- `config/package.use/*` - Per-package USE flags
- `config/package.env/*` - Compiler override rules
- `scripts/*.sh` - Installation scripts (run in order)
- `config/kernel/config` - Kernel configuration fragment

## Architecture Decisions

### Init System
- OpenRC only, no systemd
- TTY autologin via /etc/inittab modification
- startx triggered from .bash_profile

### Graphics
- NVIDIA open kernel driver (kernel-open USE flag)
- Nouveau blacklisted
- No Wayland (X11 only)

### Audio
- PipeWire with WirePlumber
- PulseAudio compatibility layer
- Real-time scheduling via rtkit

### Optimizations
- `-march=native -mtune=native -O3` base flags
- LTO enabled globally (`-flto=auto`)
- Graphite loop optimizations
- Package-specific overrides in `package.env/`

## Script Execution Order

Scripts are numbered and must run in sequence:
1. `00-create-usb.sh` - Run from host machine
2. `01-partition.sh` through `03-chroot-setup.sh` - Run from live USB
3. `04-portage-config.sh` through `99-finalize.sh` - Run inside chroot

## Modification Guidelines

### Adding Packages
1. Add USE flags to appropriate file in `config/package.use/`
2. If LTO-sensitive, add to `config/package.env/no-lto`
3. If math-sensitive, add to `config/package.env/safe-math`

### Kernel Configuration
- Fragment in `config/kernel/config` is merged with defconfig
- Key requirements: no nouveau, KVM modules, NVIDIA-compatible

### Testing Changes
- Scripts are idempotent where possible
- Test in VM before bare metal deployment
