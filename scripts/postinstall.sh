#!/usr/bin/env bash
# ============================================================================
# Arch Linux — Setup estilo macOS (GNOME)
# Ejecutar como usuario normal después del primer boot
# Uso: bash postinstall.sh [--all | --gnome | --theme | --extensions | --fonts | --terminal | --spotlight | --apps | --tweaks | --wallpapers | --gdm | --cachyos]
# Sin argumentos = menú interactivo
# ============================================================================
set -euo pipefail

# ── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${B}[INFO]${NC}  $1"; }
ok()    { echo -e "${G}[OK]${NC}    $1"; }
warn()  { echo -e "${Y}[WARN]${NC}  $1"; }
fail()  { echo -e "${R}[FAIL]${NC}  $1"; exit 1; }
step()  { echo -e "\n${C}━━━ $1 ━━━${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="${SCRIPT_DIR}/../configs"
LOG_FILE="/tmp/arch-macos-setup.log"

[[ ! -d "$CONFIGS_DIR" ]] && fail "Directorio de configs no encontrado: $CONFIGS_DIR"

# ── Sincronizar base de datos de pacman ───────────────────────────────────
info "Sincronizando base de datos de pacman..."
sudo pacman -Sy --noconfirm &>/dev/null
ok "Base de datos sincronizada"

# ── Helpers ────────────────────────────────────────────────────────────────
pac_install() {
    info "Instalando (pacman): $*"
    sudo pacman -S --noconfirm --needed "$@" 2>&1 | tee -a "$LOG_FILE"
}

aur_install() {
    info "Instalando (AUR): $*"
    yay -S --noconfirm --needed "$@" 2>&1 | tee -a "$LOG_FILE"
}

ensure_yay() {
    if ! command -v yay &>/dev/null; then
        step "Instalando yay (AUR helper)"
        pac_install git base-devel go
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
        (cd "$tmpdir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmpdir"
        ok "yay instalado"
    else
        ok "yay ya está instalado"
    fi
}

# ============================================================================
# MÓDULOS
# ============================================================================

install_gnome() {
    step "1/8 — GNOME Mínimo"

    # Shell y display manager
    pac_install \
        gnome-shell \
        gdm \
        gnome-control-center \
        gnome-tweaks \
        gnome-shell-extensions \
        gnome-keyring \
        gnome-menus

    # File manager
    pac_install nautilus

    # Utilidades mínimas
    pac_install \
        xdg-user-dirs \
        xdg-desktop-portal-gnome \
        file-roller \
        evince \
        eog \
        gnome-calculator \
        gnome-calendar \
        gnome-disk-utility \
        gnome-system-monitor \
        gvfs \
        gvfs-mtp

    # Crear carpetas estándar (Documents, Downloads, Pictures, etc.)
    xdg-user-dirs-update

    sudo systemctl enable gdm
    ok "GNOME mínimo instalado y GDM habilitado"

    # ── Remover bloat de dependencias ──
    info "Removiendo apps innecesarias (dependencias no deseadas)..."

    if pacman -Q gvfs-dnssd &>/dev/null; then
        sudo pacman -Rns --noconfirm gvfs-dnssd
    fi

    if pacman -Q avahi &>/dev/null; then
        sudo pacman -Rns --noconfirm avahi 2>/dev/null || {
            warn "avahi es dependencia requerida — ocultando apps del menú"
            mkdir -p "$HOME/.local/share/applications"
            for app in bssh bvnc avahi-discover; do
                printf '[Desktop Entry]\nNoDisplay=true\n' > "$HOME/.local/share/applications/${app}.desktop"
            done
        }
    fi

    if pacman -Q v4l-utils &>/dev/null; then
        sudo pacman -Rns --noconfirm v4l-utils 2>/dev/null || {
            warn "v4l-utils es dependencia requerida — ocultando apps del menú"
            mkdir -p "$HOME/.local/share/applications"
            for app in qv4l2 qvidcap; do
                printf '[Desktop Entry]\nNoDisplay=true\n' > "$HOME/.local/share/applications/${app}.desktop"
            done
        }
    fi

    ok "Bloat removido"

    # ── Paquetes opcionales (descomenta lo que necesites) ──
    # pac_install gnome-font-viewer      # Visor de fuentes
    # pac_install gnome-logs             # Visor de logs del sistema
    # pac_install gnome-characters       # Mapa de caracteres / emojis
    # pac_install baobab                 # Analizador de uso de disco
    # pac_install gnome-clocks           # Reloj mundial / alarmas / timer
    # pac_install gnome-weather          # Clima
    # pac_install gnome-text-editor      # Editor de texto simple
    # pac_install seahorse               # Gestor de contraseñas/llaves
    # pac_install simple-scan            # Escaneo de documentos
}

install_theme() {
    step "2/8 — Tema WhiteSur (macOS)"

    # Remover versiones -git si existen (evita conflictos)
    local git_pkgs=""
    for pkg in whitesur-gtk-theme-git whitesur-icon-theme-git whitesur-cursor-theme-git; do
        pacman -Q "$pkg" &>/dev/null && git_pkgs+="$pkg "
    done
    if [[ -n "$git_pkgs" ]]; then
        warn "Removiendo versiones -git conflictivas: $git_pkgs"
        sudo pacman -Rns --noconfirm $git_pkgs
    fi

    pac_install sassc
    aur_install gtk-engine-murrine whitesur-gtk-theme whitesur-icon-theme whitesur-cursor-theme

    ok "Tema WhiteSur instalado"

    info "Aplicando tema WhiteSur a apps libadwaita (GTK4)..."
    local whitesur_tmp
    whitesur_tmp=$(mktemp -d)
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$whitesur_tmp"
    (cd "$whitesur_tmp" && ./install.sh -l)
    rm -rf "$whitesur_tmp"
    ok "Override GTK4/libadwaita aplicado (botones macOS en todas las ventanas)"

    info "Para parchear GDM: cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g"
}

install_extensions() {
    step "3/8 — Extensiones GNOME"

    aur_install \
        gnome-shell-extension-dash-to-dock \
        gnome-shell-extension-blur-my-shell \
        gnome-shell-extension-user-themes \
        gnome-shell-extension-appindicator \
        gnome-shell-extension-vitals \
        gnome-shell-extension-just-perfection-desktop \
        gnome-shell-extension-clipboard-indicator \
        gnome-shell-extension-hidetopbar-git

    ok "Extensiones instaladas"

    # Extensión custom: dock magnification (fish-eye macOS)
    info "Instalando extensión dock-magnify..."
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/dock-magnify@archlinux-setup"
    mkdir -p "$ext_dir"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/metadata.json" "$ext_dir/"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/extension.js" "$ext_dir/"
    cp "${CONFIGS_DIR}/gnome/dock-magnify/stylesheet.css" "$ext_dir/"
    ok "Extensión dock-magnify instalada"

    warn "Actívalas en GNOME Extensions después de reiniciar la sesión"
}

install_fonts() {
    step "4/8 — Fuentes del sistema"

    aur_install ttf-inter ttf-jetbrains-mono-nerd

    ok "Fuentes instaladas"
}

install_terminal() {
    step "5/8 — Terminal (Kitty + Zsh + Starship)"

    pac_install kitty zsh starship
    aur_install zsh-autosuggestions zsh-syntax-highlighting

    # Copiar configs
    info "Copiando configuración de Kitty..."
    mkdir -p "$HOME/.config/kitty"
    cp "${CONFIGS_DIR}/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ok "kitty.conf copiado"

    info "Copiando configuración de Starship..."
    mkdir -p "$HOME/.config"
    cp "${CONFIGS_DIR}/starship/starship.toml" "$HOME/.config/starship.toml"
    ok "starship.toml copiado"

    # Configurar .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
        warn ".zshrc existente respaldado en .zshrc.bak"
    fi
    info "Configurando .zshrc..."
    cat > "$HOME/.zshrc" <<'ZSHRC'
# ── Plugins ───────────────────────────────────────────────────────────────
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Starship prompt ───────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Aliases ────────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias open='xdg-open'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'

# ── Path ───────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
ZSHRC

    # Cambiar shell a zsh
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Cambiando shell a zsh..."
        chsh -s "$(which zsh)" 2>/dev/null || \
            warn "No se pudo cambiar el shell automáticamente. Ejecuta: chsh -s \$(which zsh)"
    fi

    ok "Terminal configurada"
}

install_spotlight() {
    step "6/8 — Ulauncher (Spotlight equivalent)"

    aur_install ulauncher

    # Habilitar autostart
    systemctl --user enable ulauncher 2>/dev/null || true
    systemctl --user start ulauncher 2>/dev/null || true

    ok "Ulauncher instalado"
    info "Configura el hotkey en Ulauncher → Preferences (Alt+Space recomendado)"
}

install_apps() {
    step "7/8 — Apps, seguridad y entorno de desarrollo"

    # Apps
    pac_install flameshot
    aur_install google-chrome microsoft-edge-stable-bin

    # Firewall
    pac_install ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
    sudo systemctl enable ufw
    ok "Firewall (ufw) configurado — deny incoming, allow outgoing"

    # Containers para desarrollo
    pac_install podman distrobox
    ok "Distrobox + Podman instalados"

    ok "Apps, seguridad y entorno de desarrollo listos"
}

apply_tweaks() {
    step "8/8 — Configuración GNOME (dconf)"

    if ! command -v dconf &>/dev/null; then
        warn "dconf no disponible — ejecuta este paso después del primer login con GNOME"
        return
    fi

    info "Desactivando validación de versión de extensiones (necesario para extensiones custom)..."
    gsettings set org.gnome.shell disable-extension-version-validation true

    info "Cargando configuración GNOME desde gnome-macos.dconf..."
    dconf load / < "${CONFIGS_DIR}/gnome/gnome-macos.dconf"

    ok "Configuración GNOME aplicada (tema, fuentes, extensiones, touchpad, layout)"
}

install_wallpapers() {
    step "Wallpapers dinámicos (cambian según la hora)"

    local tmpdir
    tmpdir=$(mktemp -d)

    info "Clonando WhiteSur-wallpapers..."
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-wallpapers.git "$tmpdir" \
        2>&1 | tee -a "$LOG_FILE"

    info "Instalando wallpapers dinámicos..."
    (cd "$tmpdir" && bash install-gnome-backgrounds.sh) 2>&1 | tee -a "$LOG_FILE"

    rm -rf "$tmpdir"

    # Activar el wallpaper dinámico Ventura automáticamente
    local ventura_xml="$HOME/.local/share/backgrounds/Ventura/Ventura-timed.xml"
    if [[ -f "$ventura_xml" ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${ventura_xml}"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${ventura_xml}"
        gsettings set org.gnome.desktop.background picture-options "zoom"
        ok "Wallpaper dinámico Ventura activado — cambia automáticamente con la hora"
    else
        ok "Wallpapers instalados"
        warn "Seleccioná un wallpaper WhiteSur en Configuración → Fondo de pantalla"
    fi
}

_gdm_patch_css() {
    local gresource="/usr/share/gnome-shell/gnome-shell-theme.gresource"
    local workdir
    workdir=$(mktemp -d)

    # Extraer todos los recursos del gresource instalado
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

    # Reconstruir el gresource.xml a partir de los recursos extraídos
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

    # Recompilar y reemplazar
    (cd "$workdir" && sudo glib-compile-resources patch.gresource.xml \
        --sourcedir="$workdir" \
        --target="$gresource") 2>&1 | tee -a "$LOG_FILE"

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
        sudo pacman -S --noconfirm imagemagick 2>&1 | tee -a "$LOG_FILE"
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

_gdm_ensure_wallpapers() {
    local sys_dir="/usr/share/backgrounds/Ventura"
    local user_dir="$HOME/.local/share/backgrounds/Ventura"

    if [[ ! -f "$sys_dir/Ventura-light.jpg" || ! -f "$sys_dir/Ventura-dark.jpg" ]]; then
        if [[ -d "$user_dir" ]]; then
            info "Copiando wallpapers Ventura a ubicación del sistema..."
            sudo mkdir -p "$sys_dir"
            sudo cp "$user_dir"/*.jpg "$sys_dir/" 2>/dev/null || true
            [[ -f "$user_dir/Ventura-timed.xml" ]] && sudo cp "$user_dir/Ventura-timed.xml" "$sys_dir/"
            ok "Wallpapers copiados a $sys_dir"
        else
            warn "Wallpapers Ventura no encontrados — corré --wallpapers primero"
            return
        fi
    fi

    _gdm_generate_blur "$sys_dir"
}

_gdm_setup_dynamic_wallpaper() {
    info "Instalando servicio de wallpaper dinámico..."

    sudo install -m 755 "${SCRIPT_DIR}/gdm-wallpaper-update.sh" /usr/local/bin/gdm-wallpaper-update

    sudo tee /etc/systemd/system/gdm-wallpaper.service > /dev/null <<'UNIT'
[Unit]
Description=Update GDM wallpaper based on time of day

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gdm-wallpaper-update
UNIT

    sudo tee /etc/systemd/system/gdm-wallpaper.timer > /dev/null <<'UNIT'
[Unit]
Description=Update GDM wallpaper hourly

[Timer]
OnBootSec=0
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
UNIT

    sudo systemctl daemon-reload
    sudo systemctl enable --now gdm-wallpaper.timer 2>&1 | tee -a "$LOG_FILE"
    sudo /usr/local/bin/gdm-wallpaper-update
    ok "Wallpaper dinámico configurado (actualiza al bootear y cada hora)"
}

apply_gdm() {
    step "Login — GDM estilo macOS con wallpaper dinámico"

    _gdm_ensure_wallpapers

    local tmpdir
    tmpdir=$(mktemp -d)

    info "Clonando WhiteSur-gtk-theme..."
    git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmpdir" \
        2>&1 | tee -a "$LOG_FILE"

    info "Aplicando tema WhiteSur a GDM (requiere sudo)..."
    (cd "$tmpdir" && sudo ./tweaks.sh -g -nd -b default) 2>&1 | tee -a "$LOG_FILE"

    rm -rf "$tmpdir"

    _gdm_setup_dynamic_wallpaper

    info "Parcheando gresource (panel, logo, avatar, botones, fondo dinámico)..."
    _gdm_patch_css

    _lock_screen_patch_css

    ok "GDM configurado — login limpio con wallpaper dinámico"
    warn "Corré: sudo systemctl restart gdm"
}

install_cachyos_repos() {
    step "CachyOS — Repos optimizados + kernel BORE/EEVDF"

    if grep -q "\[cachyos" /etc/pacman.conf; then
        ok "Repos de CachyOS ya están configurados en /etc/pacman.conf"
        return
    fi

    local tmpdir
    tmpdir=$(mktemp -d)

    info "Descargando script oficial de CachyOS..."
    curl -L "https://mirror.cachyos.org/cachyos-repo.tar.xz" -o "$tmpdir/cachyos-repo.tar.xz" \
        2>&1 | tee -a "$LOG_FILE"
    tar xf "$tmpdir/cachyos-repo.tar.xz" -C "$tmpdir"

    info "Configurando repos (auto-detecta x86-64-v3 o v4 según tu CPU)..."
    (cd "$tmpdir/cachyos-repo" && sudo ./cachyos-repo.sh)

    rm -rf "$tmpdir"

    info "Actualizando sistema con paquetes optimizados (puede tardar varios minutos)..."
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"

    info "Instalando kernel CachyOS (BORE/EEVDF scheduler)..."
    sudo pacman -S --noconfirm --needed linux-cachyos linux-cachyos-headers \
        2>&1 | tee -a "$LOG_FILE"

    if command -v grub-mkconfig &>/dev/null; then
        info "Regenerando configuración de GRUB..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    ok "Repos CachyOS activos — sistema actualizado con instrucciones optimizadas"
    ok "Kernel linux-cachyos instalado (BORE/EEVDF scheduler)"
    warn "IMPORTANTE: reinicia para bootear con el nuevo kernel"
}

# ============================================================================
# MENÚ PRINCIPAL
# ============================================================================

run_all() {
    ensure_yay
    install_gnome
    install_theme
    install_extensions
    install_fonts
    install_terminal
    install_spotlight
    install_apps
    install_wallpapers
    apply_tweaks

    echo ""
    echo -e "${G}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}║  ✓ Setup completo — reinicia la sesión para        ║${NC}"
    echo -e "${G}║    ver todos los cambios                            ║${NC}"
    echo -e "${G}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Post-setup manual:"
    echo "  • Activar extensiones en GNOME Extensions"
    echo "  • Parchear GDM: cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g"
    echo "  • Configurar Ulauncher hotkey (Alt+Space)"
    echo "  • Descargar wallpapers macOS y aplicarlos"
    echo ""
}

show_menu() {
    ensure_yay

    while true; do
        echo -e "\n${C}╔══════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║  Arch Linux — Setup estilo macOS                    ║${NC}"
        echo -e "${C}╚══════════════════════════════════════════════════════╝${NC}\n"
        echo "  1) Instalar todo (recomendado)"
        echo "  2) Solo GNOME base"
        echo "  3) Solo tema WhiteSur"
        echo "  4) Solo extensiones GNOME"
        echo "  5) Solo fuentes"
        echo "  6) Solo terminal (Kitty + Zsh + Starship)"
        echo "  7) Solo Ulauncher"
        echo "  8) Solo apps"
        echo "  9) Solo ajustes finales"
        echo "  w) Wallpapers dinámicos (cambian por hora)"
        echo "  g) Login GDM estilo macOS (solo botón apagado)"
        echo "  c) CachyOS repos + kernel BORE (performance)"
        echo "  0) Salir"
        echo ""
        read -rp "Selecciona una opción: " choice

        case $choice in
            1) run_all; break ;;
            2) install_gnome; break ;;
            3) install_theme; break ;;
            4) install_extensions; break ;;
            5) install_fonts; break ;;
            6) install_terminal; break ;;
            7) install_spotlight; break ;;
            8) install_apps; break ;;
            9) apply_tweaks; break ;;
            w) install_wallpapers; break ;;
            g) apply_gdm; break ;;
            c) install_cachyos_repos; break ;;
            0) exit 0 ;;
            *) warn "Opción inválida" ;;
        esac
    done
}

# ── CLI args ───────────────────────────────────────────────────────────────
case "${1:-}" in
    --all)        ensure_yay; run_all ;;
    --gnome)      ensure_yay; install_gnome ;;
    --theme)      ensure_yay; install_theme ;;
    --extensions) ensure_yay; install_extensions ;;
    --fonts)      ensure_yay; install_fonts ;;
    --terminal)   ensure_yay; install_terminal ;;
    --spotlight)  ensure_yay; install_spotlight ;;
    --apps)       ensure_yay; install_apps ;;
    --tweaks)      apply_tweaks ;;
    --wallpapers)  install_wallpapers ;;
    --gdm)         apply_gdm ;;
    --cachyos)     install_cachyos_repos ;;
    "")            show_menu ;;
    *)             echo "Uso: $0 [--all|--gnome|--theme|--extensions|--fonts|--terminal|--spotlight|--apps|--tweaks|--wallpapers|--gdm|--cachyos]"; exit 1 ;;
esac
