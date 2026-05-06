# Arch Linux — Setup estilo macOS (mínimo)

Instalación automatizada de Arch Linux con GNOME mínimo, sin bloatware, configurado para verse como macOS. Incluye optimizaciones de performance opcionales via CachyOS.

## Stack

**Arch Linux + GNOME (mínimo)** · WhiteSur theme · Kitty + Zsh + Starship · CachyOS (opcional)

## Estructura

```
archlinux-setup/
├── scripts/
│   ├── install.sh              # Instalación base (UEFI/GPT)
│   └── postinstall.sh          # Setup visual macOS + apps + performance
├── configs/
│   ├── kitty/kitty.conf        # Terminal con Catppuccin Mocha
│   ├── starship/starship.toml  # Prompt minimalista con iconos
│   └── gnome/
│       ├── gnome-macos.dconf   # Configuración GNOME completa
│       └── dock-magnify/       # Extensión custom: fish-eye en el dock
└── README.md
```

## Requisitos

- USB live de Arch Linux (bootear en modo **UEFI**, no Legacy)
- Conexión a internet (WiFi o Ethernet)
- Disco destino identificado (`lsblk` para verificar)

---

## Paso 1 — Instalación base (desde el USB live)

1. Bootear el USB en modo **UEFI** desde el BIOS
2. Conectar a internet:

```bash
# WiFi
iwctl
station wlan0 connect "TU_SSID"

# Ethernet: debería conectar automáticamente
```

3. Descargar y ejecutar:

```bash
curl -LO https://raw.githubusercontent.com/Jufedev/archlinux-setup/main/scripts/install.sh
bash install.sh
```

El script se encarga de todo automáticamente:
- Verifica internet, sincroniza el reloj (NTP) y actualiza el keyring
- Te pide los datos de forma interactiva (disco, hostname, usuario, timezone)
- Muestra los discos disponibles y un resumen antes de confirmar
- Particiona (GPT), formatea, instala el sistema base y configura GRUB

4. Al terminar:

```bash
umount -R /mnt
reboot
```

> La contraseña temporal es tu nombre de usuario. El sistema te pedirá cambiarla en el primer login.

---

## Paso 2 — Post-instalación (después del primer boot)

Clonar el repo (si no lo tenés) y ejecutar:

```bash
git clone https://github.com/Jufedev/archlinux-setup.git ~/archlinux-setup
cd ~/archlinux-setup
bash scripts/postinstall.sh --all
```

Esto instala todo de una vez: GNOME, tema, extensiones, fuentes, terminal, Ulauncher, apps y configuración visual.

Para elegir módulos individuales, ejecutar sin argumentos para el menú interactivo:

```bash
bash scripts/postinstall.sh
```

O usar flags directamente:

| Flag | Qué instala |
|------|-------------|
| `--all` | Todo en orden (recomendado para instalación limpia) |
| `--gnome` | GNOME mínimo + GDM |
| `--theme` | Tema WhiteSur (GTK + iconos + cursores + libadwaita) |
| `--extensions` | Extensiones GNOME + extensión dock-magnify custom |
| `--fonts` | Inter + JetBrainsMono Nerd Font |
| `--terminal` | Kitty + Zsh + Starship + plugins |
| `--spotlight` | Ulauncher |
| `--apps` | Flameshot, Chrome, Edge, ufw, Podman + Distrobox |
| `--tweaks` | Aplica toda la configuración visual desde `gnome-macos.dconf` |
| `--cachyos` | Repos optimizados + kernel BORE/EEVDF *(ver Paso 3)* |

> `--tweaks` aplica la configuración de GNOME (tema, fuentes, extensiones, touchpad, layout). Ejecutarlo siempre como último paso, o después de instalar módulos individuales.

---

## Paso 3 — Performance con CachyOS (opcional)

Este paso agrega los repositorios de CachyOS a tu instalación de Arch base, sin reemplazarla. Obtenés paquetes del sistema compilados con instrucciones optimizadas para tu CPU y un kernel con mejor responsividad de desktop.

```bash
bash scripts/postinstall.sh --cachyos
```

**Qué hace internamente:**
1. Descarga el script oficial de CachyOS y auto-detecta la ISA de tu CPU (x86-64-v3 o x86-64-v4)
2. Agrega los repos de CachyOS a `/etc/pacman.conf` e importa las GPG keys
3. Actualiza todos los paquetes del sistema a las versiones optimizadas (`pacman -Syu`)
4. Instala el kernel `linux-cachyos` con scheduler BORE/EEVDF
5. Regenera la configuración de GRUB

**Por qué vale la pena:**
- Los paquetes compilados con x86-64-v3 (AVX2/FMA) dan un uplift real de 5–20% dependiendo del workload
- El scheduler BORE/EEVDF mejora la responsividad de desktop — se nota día a día
- Tu CPU Ryzen 7 5700G (Zen 3) soporta x86-64-v3 de forma nativa

> Reiniciá después de este paso para bootear con el nuevo kernel. En GRUB vas a ver tanto `linux` (Arch stock) como `linux-cachyos` como opciones.

---

## Paso 4 — Ajustes manuales

1. **Activar extensiones** → abrir GNOME Extensions y habilitar las instaladas
2. **Parchear GDM** → `cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g`
3. **Ulauncher hotkey** → abrir Preferences y configurar Alt+Space
4. **Wallpaper** → descargar desde [Basic Apple Guy](https://basicappleguy.com/basicappleblog/macOS-sonoma-wallpapers)

---

## Qué se instala (y qué NO)

### GNOME mínimo (en vez del metapaquete `gnome` con ~40 apps)

**Sí se instala:**
gnome-shell, gdm, gnome-control-center, gnome-tweaks, gnome-shell-extensions,
gnome-keyring, nautilus, xdg-user-dirs, xdg-desktop-portal-gnome, file-roller,
evince, eog, gnome-calculator, gnome-calendar, gnome-disk-utility,
gnome-system-monitor, gvfs, gvfs-mtp

**NO se instala:**
gnome-terminal (usamos Kitty), GNOME Maps, Weather, Music, Photos, Contacts,
Cheese, Totem, Epiphany, GNOME Boxes, Connections, Characters, Logs, Tour,
Console, ni ningún juego

### Extensiones GNOME

| Extensión | Función |
|-----------|---------|
| Dash to Dock | Dock estilo macOS siempre visible |
| Blur My Shell | Blur en el dock y panel |
| User Themes | Temas de shell custom |
| AppIndicator | Soporte para iconos en bandeja del sistema |
| Vitals | Monitor de recursos en la barra (equivalente a iStatMenus) |
| Just Perfection | Ajustes finos de la interfaz |
| Clipboard Indicator | Historial del portapapeles |
| HideTopBar | Oculta la barra superior automáticamente |
| **dock-magnify** *(custom)* | **Fish-eye en el dock al pasar el cursor** |

La extensión `dock-magnify` está incluida en el repo (`configs/gnome/dock-magnify/`) y se instala automáticamente con `--extensions`. No requiere ningún paso extra.

### Equivalencias macOS → Linux

| macOS | Linux | Paquete |
|---|---|---|
| Finder | Nautilus | `nautilus` |
| iTerm2 | Kitty | `kitty` |
| Spotlight | Ulauncher | `ulauncher` |
| Screenshot | Flameshot | `flameshot` |
| Preview | Evince + Eye of GNOME | `evince` `eog` |
| Archive Utility | File Roller | `file-roller` |
| Disk Utility | GNOME Disks | `gnome-disk-utility` |
| Activity Monitor | System Monitor | `gnome-system-monitor` |
| Calculator | GNOME Calculator | `gnome-calculator` |
| Calendar | GNOME Calendar | `gnome-calendar` |
| iStatMenus | Vitals | `gnome-shell-extension-vitals` |
| Safari / Chrome | Google Chrome | `google-chrome` (AUR) |
| — | Microsoft Edge | `microsoft-edge-stable-bin` (AUR) |
| — | ufw (firewall) | `ufw` |
| Docker Desktop | Podman + Distrobox | `podman` `distrobox` |

### Paquetes opcionales (descomenta en el script)

```
gnome-font-viewer    — visor de fuentes
gnome-logs           — visor de logs del sistema
gnome-characters     — mapa de caracteres / emojis
baobab               — analizador de uso de disco
gnome-clocks         — reloj mundial / alarmas
gnome-weather        — clima
gnome-text-editor    — editor de texto simple
seahorse             — gestor de contraseñas/llaves
simple-scan          — escaneo de documentos
```

---

## Hardware compatible

- Ryzen 7 5700G

---

## TODO

- [ ] Exportar versiones exactas de paquetes instalados
- [ ] Dock magnify: modo sin hover (magnificación always-on estilo macOS)
