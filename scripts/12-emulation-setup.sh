#!/usr/bin/env bash
# Install MAME for vintage system emulation
# Run inside chroot after: ./11-virt-setup.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_root
require_chroot

info "Installing MAME..."
emerge --verbose games-emulation/mame

# Get username
read -rp "Enter username to configure MAME for: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty"

USER_HOME="/home/${USERNAME}"

info "Creating MAME directory structure..."
mkdir -p "${USER_HOME}/.mame"/{roms,nvram,cfg,inp,snap,diff,comments}
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.mame"

info "Generating default MAME configuration..."
cat > "${USER_HOME}/.mame/mame.ini" << 'EOF'
#
# MAME Configuration
#

# Paths
rompath                   $HOME/.mame/roms
hashpath                  /usr/share/mame/hash
samplepath                $HOME/.mame/samples
artpath                   $HOME/.mame/artwork
ctrlrpath                 $HOME/.mame/ctrlr
inipath                   $HOME/.mame;/etc/mame
fontpath                  /usr/share/mame/fonts
cheatpath                 $HOME/.mame/cheat

# Output directories
nvram_directory           $HOME/.mame/nvram
cfg_directory             $HOME/.mame/cfg
input_directory           $HOME/.mame/inp
snapshot_directory        $HOME/.mame/snap
diff_directory            $HOME/.mame/diff
comment_directory         $HOME/.mame/comments

# Video options
video                     opengl
numscreens                1
window                    0
maximize                  1
waitvsync                 1
syncrefresh               0
prescale                  1
filter                    1

# Sound options
sound                     1
samplerate                48000
samples                   1

# Input options
coin_lockout              1
mouse                     1
joystick                  1
lightgun                  0
multikeyboard             0
multimouse                0
steadykey                 0

# Misc options
artwork_crop              0
use_backdrops             1
use_overlays              1
use_bezels                1
EOF

chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.mame/mame.ini"

success "MAME installed!"
echo ""
echo "ROMs go in: ~/.mame/roms/"
echo ""
echo "List available machines:"
echo "  mame -listfull | head -50"
echo ""
echo "Run a machine:"
echo "  mame <machine_name>"
echo ""
echo "Next: Run ./13-crossdev-setup.sh"
