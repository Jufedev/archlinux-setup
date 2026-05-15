#!/usr/bin/env bash
# Updates the GDM wallpaper symlink based on current time of day.
# WhiteSur schedule: light 7AM–7PM, dark otherwise.
set -euo pipefail

WALLPAPER_DIR="/usr/share/backgrounds/WhiteSur"
SYMLINK="/usr/share/backgrounds/gdm-current.jpg"

hour=$(date +%-H)

if (( hour >= 7 && hour < 19 )); then
  src="${WALLPAPER_DIR}/WhiteSur-light-blur.jpg"
else
  src="${WALLPAPER_DIR}/WhiteSur-blur.jpg"
fi

[[ -f "$src" ]] && ln -sf "$src" "$SYMLINK"
