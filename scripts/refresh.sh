#!/usr/bin/env bash
# ============================================================================
# Arch Linux — Refresh de configuraciones
# Aplica cambios de configs sin reinstalar. Ideal para prueba y error.
# Uso: bash scripts/refresh.sh [--all | --configs | --dconf | --dock | --gdm]
# Sin argumentos = --all (todo excepto GDM)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="${SCRIPT_DIR}/../configs"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${B}[INFO]${NC}  $1"; }
ok()    { echo -e "${G}[OK]${NC}    $1"; }
warn()  { echo -e "${Y}[WARN]${NC}  $1"; }

[[ ! -d "$CONFIGS_DIR" ]] && { echo -e "${R}[FAIL]${NC}  Configs no encontradas: $CONFIGS_DIR"; exit 1; }

# ── Kitty + Starship ──────────────────────────────────────────────────────
refresh_configs() {
    info "Copiando configs de terminal..."
    mkdir -p "$HOME/.config/kitty"
    cp "${CONFIGS_DIR}/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ok "kitty.conf"

    cp "${CONFIGS_DIR}/starship/starship.toml" "$HOME/.config/starship.toml"
    ok "starship.toml"
}

# ── GNOME dconf ───────────────────────────────────────────────────────────
refresh_dconf() {
    if ! command -v dconf &>/dev/null; then
        warn "dconf no disponible — ejecutá esto desde una sesión GNOME"
        return
    fi
    gsettings set org.gnome.shell disable-extension-version-validation true
    info "Aplicando gnome-macos.dconf..."
    dconf load / < "${CONFIGS_DIR}/gnome/gnome-macos.dconf"
    ok "dconf aplicado"
}

# ── Extensión dock-magnify ────────────────────────────────────────────────
refresh_dock() {
    local uuid="dock-magnify@archlinux-setup"
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$uuid"

    info "Copiando archivos de dock-magnify..."
    mkdir -p "$ext_dir"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/extension.js"  "$ext_dir/"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/metadata.json" "$ext_dir/"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/stylesheet.css" "$ext_dir/"
    ok "Archivos copiados"

    if command -v gnome-extensions &>/dev/null; then
        info "Recargando extensión..."
        gnome-extensions disable "$uuid" 2>/dev/null || true
        sleep 0.3
        gnome-extensions enable  "$uuid" 2>/dev/null || true
        ok "dock-magnify recargado"
    else
        warn "gnome-extensions no disponible — reiniciá la sesión GNOME para ver los cambios"
    fi
}

# ── GDM (lento, requiere sudo) ────────────────────────────────────────────
refresh_gdm() {
    warn "El refresh de GDM re-aplica el tema completo — puede tardar 1-2 min"
    local tmpdir
    tmpdir=$(mktemp -d)

    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmpdir" \
        2>&1 | grep -E "Cloning|done\."

    local hide_a11y="#AccessibilityButton { display: none !important; }"
    echo "$hide_a11y" >> "${tmpdir}/src/main/gnome-shell/gnome-shell-Light.scss"
    echo "$hide_a11y" >> "${tmpdir}/src/main/gnome-shell/gnome-shell-Dark.scss"

    local ventura_img="/usr/share/backgrounds/Ventura/Ventura-light.jpg"
    local gdm_bg_flag="-b default"
    if [[ -f "$ventura_img" ]]; then
        gdm_bg_flag="-b ${ventura_img}"
    fi

    # shellcheck disable=SC2086
    (cd "$tmpdir" && sudo ./tweaks.sh -g -nd $gdm_bg_flag)
    rm -rf "$tmpdir"

    ok "GDM actualizado"
    warn "Corré 'sudo systemctl restart gdm' para aplicar (cierra la sesión actual)"
}

# ── Todo (sin GDM) ────────────────────────────────────────────────────────
refresh_wallpaper() {
    local ventura_xml="$HOME/.local/share/backgrounds/Ventura/Ventura-timed.xml"
    if [[ ! -f "$ventura_xml" ]]; then
        warn "Wallpapers no instalados — corré: bash scripts/postinstall.sh --wallpapers"
        return
    fi
    gsettings set org.gnome.desktop.background picture-uri "file://${ventura_xml}"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://${ventura_xml}"
    gsettings set org.gnome.desktop.background picture-options "zoom"
    ok "Wallpaper dinámico Ventura activado"
}

refresh_all() {
    refresh_configs
    refresh_dconf
    refresh_dock
    refresh_wallpaper
    echo ""
    ok "Refresh completo — configs, dconf, dock-magnify y wallpaper actualizados"
    info "Para actualizar el GDM corré: bash scripts/refresh.sh --gdm"
}

# ── CLI ───────────────────────────────────────────────────────────────────
case "${1:-}" in
    --configs)   refresh_configs ;;
    --dconf)     refresh_dconf ;;
    --dock)      refresh_dock ;;
    --wallpaper) refresh_wallpaper ;;
    --gdm)       refresh_gdm ;;
    --all|"")    refresh_all ;;
    *) echo "Uso: $0 [--all | --configs | --dconf | --dock | --gdm]"; exit 1 ;;
esac
