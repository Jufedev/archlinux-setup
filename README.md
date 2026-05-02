# Arch Linux — Setup estilo macOS (mínimo)

Instalación automatizada de Arch Linux con GNOME mínimo, sin bloatware, configurado para verse como macOS.

## Stack

**Arch Linux + GNOME (mínimo)** · WhiteSur theme · Kitty + Zsh + Starship

## Estructura

```
arch-setup/
├── scripts/
│   ├── install.sh              # Instalación base (UEFI/GPT)
│   └── postinstall.sh          # Setup visual macOS + apps
├── configs/
│   ├── kitty/kitty.conf        # Terminal con Catppuccin Mocha
│   ├── starship/starship.toml  # Prompt minimalista con iconos
│   └── gnome/gnome-macos.dconf # Configuración GNOME completa
└── README.md
```

## Requisitos

- USB live de Arch Linux (bootear en modo **UEFI**, no Legacy)
- Conexión a internet (WiFi o Ethernet)
- Disco destino identificado (`lsblk` para verificar)

## Uso

### Paso 1 — Instalación base (desde el USB live)

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

### Paso 2 — Post-instalación (después del primer boot)

Loguearse y ejecutar:

```bash
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
| `--gnome` | GNOME mínimo + GDM |
| `--theme` | Tema WhiteSur (GTK + iconos + cursores) |
| `--extensions` | Extensiones GNOME (Dash to Dock, Blur, Vitals, etc.) |
| `--fonts` | Inter + JetBrainsMono Nerd Font |
| `--terminal` | Kitty + Zsh + Starship + plugins |
| `--spotlight` | Ulauncher |
| `--apps` | Flameshot |
| `--tweaks` | Aplica toda la configuración visual desde `gnome-macos.dconf` |

> `--tweaks` aplica la configuración de GNOME (tema, fuentes, extensiones, touchpad, layout). Ejecutarlo siempre como último paso, o después de instalar módulos individuales.

### Paso 3 — Ajustes manuales

1. **Activar extensiones** → abrir GNOME Extensions y habilitar las instaladas
2. **Parchear Firefox** → `cd /usr/share/themes/WhiteSur-Light && ./tweaks.sh -f monterey`
3. **Parchear GDM** → `cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g`
4. **Ulauncher hotkey** → abrir Preferences y configurar Alt+Space
5. **Wallpaper** → descargar desde [Basic Apple Guy](https://basicappleguy.com/basicappleblog/macOS-sonoma-wallpapers)

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

## Hardware compatible

- Ryzen 7 5700G

## TODO

- [ ] Script para ClamAV
- [ ] Exportar versiones exactas de paquetes instalados
