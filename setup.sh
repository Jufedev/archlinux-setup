#!/usr/bin/env bash
# Distro dispatcher — delegates to the correct postinstall.sh based on /etc/os-release.
# Usage: bash setup.sh [--all | --<module>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

distro_id="unknown"
[[ -r /etc/os-release ]] && distro_id="$(. /etc/os-release; echo "${ID:-unknown}")"

case "$distro_id" in
  arch|cachyos|endeavouros|arcolinux)
    exec bash "${SCRIPT_DIR}/arch/scripts/postinstall.sh" "$@"
    ;;
  fedora|nobara)
    exec bash "${SCRIPT_DIR}/fedora/scripts/postinstall.sh" "$@"
    ;;
  *)
    echo "Unsupported distro: '${distro_id}'. Run arch/ or fedora/ postinstall.sh directly." >&2
    exit 1
    ;;
esac
