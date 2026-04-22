#!/usr/bin/env bash
# ============================================================================
# Arch Linux — Setup estilo macOS (GNOME)
# Ejecutar como usuario normal después del primer boot
# Uso: bash postinstall.sh [--all | --gnome | --theme | --extensions | --fonts | --terminal | --apps | --tweaks]
# Sin argumentos = menú interactivo
# ============================================================================
set -euo pipefail

# ── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; C='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${B}[INFO]${NC}  $1"; }
ok()    { echo -e "${G}[OK]${NC}    $1"; }
warn()  { echo -e "${Y}[WARN]${NC}  $1"; }
step()  { echo -e "\n${C}━━━ $1 ━━━${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="${SCRIPT_DIR}/../configs"
LOG_FILE="/tmp/arch-macos-setup.log"

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
        pac_install git base-devel
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
        gnome-keyring

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

    aur_install whitesur-gtk-theme-git whitesur-icon-theme-git whitesur-cursor-theme-git

    info "Aplicando tema GTK..."
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'
    gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
    gsettings set org.gnome.desktop.interface color-scheme 'default'

    # Intentar aplicar tema al shell (requiere extensión User Themes)
    gsettings set org.gnome.shell.extensions.user-theme name 'WhiteSur-Light' 2>/dev/null || \
        warn "Activa la extensión User Themes para aplicar el tema al shell"

    ok "Tema WhiteSur aplicado"
    info "Para parchear Firefox: cd /usr/share/themes/WhiteSur-Light && ./tweaks.sh -f monterey"
    info "Para parchear GDM:     cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g"
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
        gnome-shell-extension-clipboard-indicator

    ok "Extensiones instaladas"
    warn "Actívalas en GNOME Extensions después de reiniciar la sesión"

    # Configurar Dash to Dock via dconf (si está disponible)
    if command -v dconf &>/dev/null; then
        info "Configurando Dash to Dock..."
        dconf write /org/gnome/shell/extensions/dash-to-dock/dock-position "'BOTTOM'"
        dconf write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size 48
        dconf write /org/gnome/shell/extensions/dash-to-dock/intellihide-mode "'ALL_WINDOWS'"
        dconf write /org/gnome/shell/extensions/dash-to-dock/background-opacity 0.6
        dconf write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'DYNAMIC'"
        dconf write /org/gnome/shell/extensions/dash-to-dock/running-indicator-style "'DOTS'"
        ok "Dash to Dock configurado"
    fi

    # Configurar Just Perfection
    if command -v dconf &>/dev/null; then
        info "Configurando Just Perfection..."
        dconf write /org/gnome/shell/extensions/just-perfection/activities-button false
        dconf write /org/gnome/shell/extensions/just-perfection/app-menu false
        dconf write /org/gnome/shell/extensions/just-perfection/workspace-popup false
        dconf write /org/gnome/shell/extensions/just-perfection/animation 3
        ok "Just Perfection configurado"
    fi
}

install_fonts() {
    step "4/8 — Fuentes del sistema"

    aur_install ttf-inter ttf-jetbrains-mono-nerd

    info "Aplicando fuentes en GNOME..."
    gsettings set org.gnome.desktop.interface font-name 'Inter Regular 11'
    gsettings set org.gnome.desktop.interface document-font-name 'Inter Regular 11'
    gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
    gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Medium 11'

    # Hinting y antialiasing
    gsettings set org.gnome.desktop.interface font-hinting 'slight'
    gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'

    ok "Fuentes configuradas"
}

install_terminal() {
    step "5/8 — Terminal (Kitty + Zsh + Starship)"

    pac_install kitty zsh starship
    aur_install zsh-autosuggestions zsh-syntax-highlighting

    # Instalar Oh My Zsh (no interactivo)
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Instalando Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
        ok "Oh My Zsh instalado"
    else
        ok "Oh My Zsh ya está instalado"
    fi

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
    info "Configurando .zshrc..."
    cat > "$HOME/.zshrc" <<'ZSHRC'
# ── Oh My Zsh ──────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git z)
source $ZSH/oh-my-zsh.sh

# ── Plugins externos ──────────────────────────────────────────────────────
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
    step "7/8 — Apps equivalentes a macOS"

    pac_install flameshot

    ok "Apps instaladas"
}

apply_tweaks() {
    step "8/8 — Ajustes finales estilo macOS"

    # Botones de ventana a la izquierda (como macOS)
    info "Moviendo botones de ventana a la izquierda..."
    gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

    # Scaling fraccional (para HiDPI)
    info "Habilitando scaling fraccional..."
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

    # Animaciones
    info "Configurando animaciones..."
    gsettings set org.gnome.desktop.interface enable-animations true

    # Reloj con formato 12h o 24h
    gsettings set org.gnome.desktop.interface clock-show-seconds false

    # Tap to click en touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

    ok "Ajustes aplicados"
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
    apply_tweaks

    echo ""
    echo -e "${G}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}║  ✓ Setup completo — reinicia la sesión para        ║${NC}"
    echo -e "${G}║    ver todos los cambios                            ║${NC}"
    echo -e "${G}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Post-setup manual:"
    echo "  • Activar extensiones en GNOME Extensions"
    echo "  • Parchear Firefox: cd /usr/share/themes/WhiteSur-Light && ./tweaks.sh -f monterey"
    echo "  • Parchear GDM:     cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g"
    echo "  • Configurar Ulauncher hotkey (Alt+Space)"
    echo "  • Descargar wallpapers macOS y aplicarlos"
    echo ""
}

show_menu() {
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
    echo "  0) Salir"
    echo ""
    read -rp "Selecciona una opción: " choice

    ensure_yay

    case $choice in
        1) run_all ;;
        2) install_gnome ;;
        3) install_theme ;;
        4) install_extensions ;;
        5) install_fonts ;;
        6) install_terminal ;;
        7) install_spotlight ;;
        8) install_apps ;;
        9) apply_tweaks ;;
        0) exit 0 ;;
        *) warn "Opción inválida"; show_menu ;;
    esac
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
    --tweaks)     apply_tweaks ;;
    "")           show_menu ;;
    *)            echo "Uso: $0 [--all|--gnome|--theme|--extensions|--fonts|--terminal|--spotlight|--apps|--tweaks]"; exit 1 ;;
esac
