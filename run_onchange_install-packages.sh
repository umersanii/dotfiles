#!/usr/bin/env bash
set -euo pipefail

# Core stack (official repos)
PACMAN_PKGS=(
  fish
  kitty
  starship
  matugen
  wlogout
  fuzzel
  btop
  fastfetch
  pipewire
  pipewire-alsa
  pipewire-jack
  gst-plugin-pipewire
)

# illogical-impulse rice (Hyprland + Quickshell "ii" panel) + extras, AUR
AUR_PKGS=(
  illogical-impulse-hyprland
  illogical-impulse-quickshell-git
  illogical-impulse-audio
  illogical-impulse-backlight
  illogical-impulse-basic
  illogical-impulse-bibata-modern-classic-bin
  illogical-impulse-fonts-themes
  illogical-impulse-kde
  illogical-impulse-microtex-git
  illogical-impulse-portal
  illogical-impulse-python
  illogical-impulse-screencapture
  illogical-impulse-toolkit
  illogical-impulse-widgets
  cavasik
  graphite-gtk-theme
)

if ! command -v yay >/dev/null 2>&1; then
  echo "yay not found — install an AUR helper first, e.g.:" >&2
  echo "  git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si" >&2
  exit 1
fi

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"
