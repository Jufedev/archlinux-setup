# Arch Linux — Setup estilo macOS (mínimo)

Instalación automatizada de Arch Linux con GNOME mínimo, sin bloatware, configurado para verse como macOS.

## Stack

**Arch Linux + GNOME (mínimo)** · WhiteSur theme · Kitty + Zsh + Starship

## Estructura

```
arch-setup/
├── scripts/
│   ├── install.sh          # Instalación base (desde USB live, BIOS Legacy)
│   └── postinstall.sh      # Setup macOS (GNOME, temas, terminal, apps)
├── configs/
│   ├── kitty/
│   │   └── kitty.conf      # Terminal con Catppuccin Mocha
│   ├── starship/
│   │   └── starship.toml   # Prompt minimalista con iconos
│   └── gnome/
│       └── gnome-macos.dconf  # Dump de configuración GNOME
└── README.md
```

## Uso

### 1. Instalación base (desde USB live de Arch)

```bash
iwctl                              # Conectar a internet
# station wlan0 connect "SSID"

curl -LO https://raw.githubusercontent.com/juanseproy/prueba-arch/main/scripts/install.sh
bash install.sh
```

> Edita las variables al inicio de `install.sh` (disco, hostname, timezone, usuario).

### 2. Post-instalación (después del primer boot)

```bash
cd ~/prueba-arch
bash scripts/postinstall.sh --all   # Todo de una vez
bash scripts/postinstall.sh         # Menú interactivo
```

### Módulos individuales

```bash
bash scripts/postinstall.sh --gnome       # GNOME mínimo
bash scripts/postinstall.sh --theme       # Tema WhiteSur
bash scripts/postinstall.sh --extensions  # Extensiones
bash scripts/postinstall.sh --fonts       # Fuentes
bash scripts/postinstall.sh --terminal    # Kitty + Zsh + Starship
bash scripts/postinstall.sh --spotlight   # Ulauncher
bash scripts/postinstall.sh --apps        # Apps extra
bash scripts/postinstall.sh --tweaks      # Ajustes finales
```

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

### Apps equivalentes a macOS

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

## Post-setup manual

1. **Activar extensiones** → GNOME Extensions
2. **Parchear Firefox** → `cd /usr/share/themes/WhiteSur-Light && ./tweaks.sh -f monterey`
3. **Parchear GDM** → `cd /usr/share/themes/WhiteSur-Light && sudo ./tweaks.sh -g`
4. **Ulauncher hotkey** → Alt+Space en Preferences
5. **Wallpaper** → [Basic Apple Guy](https://basicappleguy.com/basicappleblog/macOS-sonoma-wallpapers)

## Procesadores compatibles

- i3-2330M
- Ryzen 7 5700G

## TODO

- [ ] Script para ClamAV
- [ ] Exportar versiones exactas de paquetes instalados
