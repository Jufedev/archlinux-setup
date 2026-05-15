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

    local icon_src="${CONFIGS_DIR}/gnome/icons/view-app-grid-symbolic.svg"
    if [[ -f "$icon_src" ]]; then
        local found=false
        for theme_dir in /usr/share/icons/WhiteSur /usr/share/icons/WhiteSur-dark; do
            [[ ! -d "$theme_dir" ]] && continue

            while IFS= read -r existing; do
                sudo rm -f "$existing"
                sudo cp "$icon_src" "$existing"
                found=true
            done < <(find "$theme_dir" -name "view-app-grid*" \( -type f -o -type l \) 2>/dev/null)

            sudo gtk-update-icon-cache -f "$theme_dir" 2>/dev/null || true
        done

        if $found; then
            ok "Icono de app grid (9 puntos) actualizado"
        else
            warn "Tema de iconos WhiteSur no encontrado en /usr/share/icons/"
        fi
    fi

    _overview_patch_css
}

_overview_patch_css() {
    local theme_css=""
    for dir in /usr/share/themes/WhiteSur-Light "$HOME/.themes/WhiteSur-Light" "$HOME/.local/share/themes/WhiteSur-Light"; do
        if [[ -f "$dir/gnome-shell/gnome-shell.css" ]]; then
            theme_css="$dir/gnome-shell/gnome-shell.css"
            break
        fi
    done

    if [[ -z "$theme_css" ]]; then
        warn "WhiteSur-Light gnome-shell.css no encontrado — overview sin parchear"
        return
    fi

    if grep -q 'archlinux-setup-overview-patch' "$theme_css" 2>/dev/null; then
        ok "Overview CSS ya parcheado"
        return
    fi

    info "Parcheando overview: $theme_css"
    local patch
    patch=$(cat <<'CSSPATCH'

/* archlinux-setup-overview-patch */
.workspace-thumbnails {
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
}
.workspace-background {
  background-color: transparent !important;
}
CSSPATCH
)
    if [[ "$theme_css" == /usr/share/* ]]; then
        printf '%s\n' "$patch" | sudo tee -a "$theme_css" > /dev/null
    else
        printf '%s\n' "$patch" >> "$theme_css"
    fi
    ok "Workspace thumbnails ocultos via CSS (compatible con Blur My Shell)"
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
_gdm_patch_css() {
    local gresource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
    local workdir
    workdir=$(mktemp -d)

    while IFS= read -r resource; do
        local rel="${resource#/org/gnome/shell/theme/}"
        mkdir -p "$workdir/$(dirname "$rel")"
        gresource extract "$gresource" "$resource" > "$workdir/$rel" 2>/dev/null || true
    done < <(gresource list "$gresource")

    local css_patch
    css_patch=$(cat <<'CSSPATCH'

#panel {
  height: 0 !important;
  background-color: transparent !important;
}
.login-dialog-logo-bin {
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  opacity: 0 !important;
}
.user-icon,
.login-dialog .user-widget .user-icon,
.login-dialog .user-widget.vertical .user-icon {
  icon-size: 0 !important;
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
  background-color: transparent !important;
}
.user-icon StIcon,
.login-dialog .user-widget.vertical .user-icon StIcon {
  icon-size: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
}
.login-dialog-button.a11y-button,
.login-dialog-button.login-dialog-session-list-button,
.login-dialog-button.switch-user-button {
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
}
#lockDialogGroup {
  background-image: url("file:///usr/share/backgrounds/gdm-current.jpg") !important;
}
CSSPATCH
)
    while IFS= read -r css; do
        printf '%s\n' "$css_patch" >> "$css"
    done < <(find "$workdir" -name "*.css")

    local xml="$workdir/patch.gresource.xml"
    {
        echo '<?xml version="1.0" encoding="UTF-8"?>'
        echo '<gresources>'
        echo '  <gresource prefix="/org/gnome/shell/theme">'
        while IFS= read -r resource; do
            echo "    <file>${resource#/org/gnome/shell/theme/}</file>"
        done < <(gresource list "$gresource")
        echo '  </gresource>'
        echo '</gresources>'
    } > "$xml"

    (cd "$workdir" && sudo glib-compile-resources patch.gresource.xml \
        --sourcedir="$workdir" \
        --target="$gresource")

    rm -rf "$workdir"
    ok "GDM parcheado (panel, logo, avatar, botones, fondo dinámico)"
}

_lock_screen_patch_css() {
    local theme_css=""
    for dir in /usr/share/themes/WhiteSur-Light "$HOME/.themes/WhiteSur-Light" "$HOME/.local/share/themes/WhiteSur-Light"; do
        if [[ -f "$dir/gnome-shell/gnome-shell.css" ]]; then
            theme_css="$dir/gnome-shell/gnome-shell.css"
            break
        fi
    done

    if [[ -z "$theme_css" ]]; then
        warn "WhiteSur-Light gnome-shell.css no encontrado — lock screen sin parchear"
        return
    fi

    if grep -q 'archlinux-setup-lock-patch' "$theme_css" 2>/dev/null; then
        ok "Lock screen CSS ya parcheado"
        return
    fi

    info "Parcheando lock screen: $theme_css"
    local patch
    patch=$(cat <<'CSSPATCH'

/* archlinux-setup-lock-patch */
.unlock-dialog .user-widget .user-icon,
.unlock-dialog .user-widget.vertical .user-icon {
  icon-size: 0 !important;
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
  background-color: transparent !important;
}
.unlock-dialog .user-widget.vertical .user-icon StIcon {
  icon-size: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
}
.unlock-dialog .cancel-button,
.unlock-dialog .switch-user-button,
.unlock-dialog .login-dialog-session-list-button {
  width: 0 !important;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  opacity: 0 !important;
}
CSSPATCH
)
    if [[ "$theme_css" == /usr/share/* ]]; then
        printf '%s\n' "$patch" | sudo tee -a "$theme_css" > /dev/null
    else
        printf '%s\n' "$patch" >> "$theme_css"
    fi
    ok "Lock screen CSS parcheado — consistente con GDM"
}

_gdm_generate_blur() {
    local dir="$1"

    if [[ -f "$dir/Ventura-light-blur.jpg" && -f "$dir/Ventura-dark-blur.jpg" ]]; then
        return
    fi

    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        info "Instalando imagemagick para efecto blur..."
        sudo pacman -S --noconfirm imagemagick
    fi

    local blur_cmd="magick"
    command -v magick &>/dev/null || blur_cmd="convert"

    for variant in light dark; do
        local src="$dir/Ventura-${variant}.jpg"
        local dst="$dir/Ventura-${variant}-blur.jpg"
        if [[ -f "$src" && ! -f "$dst" ]]; then
            info "Generando blur: Ventura-${variant}-blur.jpg..."
            sudo "$blur_cmd" "$src" -blur 0x30 "$dst"
            ok "Ventura-${variant}-blur.jpg"
        fi
    done
}

refresh_gdm() {
    warn "Re-aplicando tema GDM — puede tardar 1-2 min"

    _gdm_generate_blur "/usr/share/backgrounds/Ventura"

    local tmpdir
    tmpdir=$(mktemp -d)

    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmpdir" \
        2>&1 | grep -E "Cloning|done\."

    (cd "$tmpdir" && sudo ./tweaks.sh -g -nd -b default)
    rm -rf "$tmpdir"

    sudo /usr/local/bin/gdm-wallpaper-update 2>/dev/null || warn "gdm-wallpaper-update no instalado — corré postinstall.sh --gdm"

    info "Parcheando gresource (panel, logo, avatar, botones, fondo dinámico)..."
    _gdm_patch_css

    _lock_screen_patch_css

    ok "GDM actualizado"
    warn "Corré: sudo systemctl restart gdm"
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
