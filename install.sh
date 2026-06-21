#!/usr/bin/env bash
# Install screen-dimmer: calibrated multi-monitor brightness + Night Light rider.
# Symlinks scripts/units back to this repo (repo stays the source of truth).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

# --- dependencies ---
command -v ddcutil >/dev/null || { echo ">> installing ddcutil"; sudo dnf install -y ddcutil; }
command -v zenity  >/dev/null || { echo ">> installing zenity";  sudo dnf install -y zenity; }

# --- i2c-dev kernel module (DDC/CI for external monitors), now + at boot ---
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
sudo modprobe i2c-dev

# --- scripts ---
mkdir -p ~/.local/bin
for f in "$here"/bin/*; do ln -sf "$f" ~/.local/bin/; done

# --- systemd user units (copied, not symlinked: systemctl enable dislikes out-of-tree symlinks) ---
mkdir -p ~/.config/systemd/user
cp "$here"/systemd/* ~/.config/systemd/user/

# --- calibration config (never clobber an existing one) ---
[ -f ~/.config/screen-bright.conf ] || cp "$here/screen-bright.conf.example" ~/.config/screen-bright.conf

# --- DDC/CI access for the active user (ddcutil ships the uaccess udev rule) ---
sudo udevadm control --reload-rules && sudo udevadm trigger

# --- the bedtime/auto dim RIDES GNOME Night Light: it must be on (set schedule + temp
#     in Settings > Display > Night Light, or it stays fixed-hours as already configured) ---
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

# --- enable the Night Light rider ---
systemctl --user daemon-reload
systemctl --user enable --now screen-auto.timer

cat <<'EOF'

Installed.
  - Calibrate per-screen bases:   $EDITOR ~/.config/screen-bright.conf
  - Master slider:                screen-slider   (bind to a hotkey if you like)
  - Manual uniform set:           screen-dim <0-100>
  - Adapt to YOUR hardware:       edit monitor models + laptop device in ~/.local/bin/screen-apply
                                  (`ddcutil detect`  /  `ls /sys/class/backlight/`)

If external monitors report "Permission denied", log out and back in once
(the uaccess ACL is granted to the active login session).
EOF
