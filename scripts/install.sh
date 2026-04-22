#!/usr/bin/env bash
# ============================================================================
# Arch Linux — Instalación base (BIOS Legacy / MBR)
# Ejecutar desde el USB live de Arch: bash install.sh
# ============================================================================
set -euo pipefail

# ── Colores ─────────────────────────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; NC='\033[0m'
info()  { echo -e "${B}[INFO]${NC}  $1"; }
ok()    { echo -e "${G}[OK]${NC}    $1"; }
warn()  { echo -e "${Y}[WARN]${NC}  $1"; }
fail()  { echo -e "${R}[FAIL]${NC}  $1"; exit 1; }

# ── Configuración ──────────────────────────────────────────────────────────
DISK="/dev/sda"          # Disco destino (cambiar si es necesario)
HOSTNAME="archlinux"
USERNAME="jufedev"
TIMEZONE="America/Bogota"
LOCALE="en_US.UTF-8"
KEYMAP="us"
REPO_URL="https://github.com/juanseproy/prueba-arch.git"

# ── Validaciones ───────────────────────────────────────────────────────────
[[ $EUID -ne 0 ]] && fail "Ejecuta este script como root"
[[ ! -b "$DISK" ]] && fail "Disco $DISK no encontrado"

echo -e "\n${Y}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${Y}║  Arch Linux — Instalación Base (BIOS Legacy)        ║${NC}"
echo -e "${Y}╚══════════════════════════════════════════════════════╝${NC}\n"

echo -e "${R}ADVERTENCIA: Esto borrará TODO en ${DISK}${NC}"
read -rp "¿Continuar? (s/N): " confirm
[[ "$confirm" != "s" && "$confirm" != "S" ]] && exit 0

# ── 1. Particionado (MBR, una sola partición) ─────────────────────────────
info "Particionando $DISK (MBR)..."
(
echo o    # Crear tabla de particiones DOS/MBR
echo n    # Nueva partición
echo p    # Primaria
echo 1    # Partición 1
echo      # Primer sector (default)
echo      # Último sector (default, usa todo el espacio)
echo w    # Guardar y salir
) | fdisk "$DISK" &>/dev/null
ok "Particionado completado"

# ── 2. Formatear y montar ──────────────────────────────────────────────────
info "Formateando ${DISK}1 como ext4..."
mkfs.ext4 -F "${DISK}1"
ok "Formato completado"

info "Montando en /mnt..."
mount "${DISK}1" /mnt
ok "Montado"

# ── 3. Instalar sistema base ──────────────────────────────────────────────
info "Instalando sistema base con pacstrap..."
pacstrap -K /mnt \
    base linux linux-firmware \
    base-devel git vim sudo \
    networkmanager grub \
    pipewire pipewire-alsa pipewire-pulse wireplumber
ok "Sistema base instalado"

# ── 4. Generar fstab ──────────────────────────────────────────────────────
info "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab generado"

# ── 5. Configuración dentro de chroot ─────────────────────────────────────
info "Configurando sistema dentro de chroot..."

arch-chroot /mnt /bin/bash <<CHROOT_SCRIPT
set -euo pipefail

# Timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# Locale
sed -i 's/#${LOCALE}/${LOCALE}/' /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Habilitar multilib (para paquetes 32-bit si se necesitan)
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

# Configurar pacman: colores y descargas paralelas
sed -i 's/#Color/Color/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf

# GRUB (BIOS Legacy)
grub-install --target=i386-pc ${DISK}
grub-mkconfig -o /boot/grub/grub.cfg

# Crear usuario
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "root:root" | chpasswd
echo "${USERNAME}:${USERNAME}" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Servicios
systemctl enable NetworkManager
systemctl enable pipewire

# Clonar repo de configuración
cd /home/${USERNAME}
git clone ${REPO_URL} || true
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

echo "✓ Chroot configurado"
CHROOT_SCRIPT

ok "Configuración de chroot completada"

# ── 6. Finalizar ──────────────────────────────────────────────────────────
echo ""
ok "Instalación base completada"
echo ""
echo -e "${G}Próximos pasos:${NC}"
echo "  1. umount -R /mnt"
echo "  2. reboot"
echo "  3. Loguearse como ${USERNAME} (contraseña: ${USERNAME})"
echo "  4. Cambiar contraseña: passwd"
echo "  5. Ejecutar: bash ~/prueba-arch/scripts/postinstall.sh"
echo ""
warn "RECUERDA cambiar la contraseña por defecto después del primer login"
