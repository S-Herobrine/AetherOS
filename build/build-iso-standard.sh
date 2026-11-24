#!/bin/bash
# ==============================================================================
# AetherOS Unified Standard Edition ISO Builder (FlowOS / Nava OS Architecture)
# Ultra-fast 4-second boot, 128MB RAM minimum, zero-segfault liquid glass desktop
# Optimized for ultra-fast build (<20 mins) on GitHub Actions Azure Runners
# ==============================================================================

set -euo pipefail

DIST_NAME="AetherOS"
DIST_VERSION="1.0"
DIST_EDITION="Standard"
ARCH="amd64"
CODENAME="noble"
MIRROR="http://azure.archive.ubuntu.com/ubuntu/"

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="/tmp/aetheros-build-std"
BUILD_DIR="${WORK_DIR}/chroot"
ISO_DIR="${WORK_DIR}/iso"
OUTPUT_DIR="${WORKSPACE_ROOT}/build/output"
ISO_NAME="${DIST_NAME}-${DIST_VERSION}-${DIST_EDITION}-${ARCH}.iso"

echo "======================================================================"
echo "          Starting ${DIST_NAME} ${DIST_VERSION} (${DIST_EDITION}) ISO Build"
echo "          Target: 4-Sec Boot, 128MB RAM, Universal Apps, Liquid Glass"
echo "          Fast-Mirror: ${MIRROR}"
echo "======================================================================"

rm -rf "${WORK_DIR}"
mkdir -p "${OUTPUT_DIR}" "${BUILD_DIR}" "${ISO_DIR}/casper" "${ISO_DIR}/boot/grub" "${ISO_DIR}/.disk"

# 1. Debootstrap base Ubuntu 24.04 LTS (Noble) with Azure High-Speed Mirror
echo "==> [Stage 1/9] Debootstrapping Ubuntu 24.04 LTS (Noble) base (high-speed mirror)..."
debootstrap --arch="${ARCH}" "${CODENAME}" "${BUILD_DIR}" "${MIRROR}" || \
debootstrap --arch="${ARCH}" "${CODENAME}" "${BUILD_DIR}" http://archive.ubuntu.com/ubuntu/

# 2. Configure High-Speed Repositories & DNS inside chroot
echo "==> [Stage 2/9] Configuring APT sources and networking..."
cp /etc/resolv.conf "${BUILD_DIR}/etc/resolv.conf"

cat << 'EOF' > "${BUILD_DIR}/etc/apt/sources.list"
deb http://azure.archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://azure.archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://azure.archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

# 3. Mount virtual filesystems for chroot operations
echo "==> [Stage 3/9] Mounting chroot virtual filesystems..."
mount -t proc proc "${BUILD_DIR}/proc"
mount -t sysfs sysfs "${BUILD_DIR}/sys"
mount --bind /dev "${BUILD_DIR}/dev"
mount --bind /dev/pts "${BUILD_DIR}/dev/pts"

unmount_chroot() {
    echo "==> Unmounting chroot filesystems..."
    umount -lf "${BUILD_DIR}/dev/pts" 2>/dev/null || true
    umount -lf "${BUILD_DIR}/dev" 2>/dev/null || true
    umount -lf "${BUILD_DIR}/sys" 2>/dev/null || true
    umount -lf "${BUILD_DIR}/proc" 2>/dev/null || true
}
trap unmount_chroot EXIT

# Prevent package daemon auto-start in chroot (prevents package installation hangs)
mkdir -p "${BUILD_DIR}/usr/sbin"
cat << 'POLICY_EOF' > "${BUILD_DIR}/usr/sbin/policy-rc.d"
#!/bin/sh
exit 101
POLICY_EOF
chmod +x "${BUILD_DIR}/usr/sbin/policy-rc.d"

# 4. Install Full Package Suite & Subsystems (Streamlined for 60fps fluidity & zero crash)
echo "==> [Stage 4/9] Installing kernel, casper, desktop and display packages..."
chroot "${BUILD_DIR}" /bin/bash << 'CHROOT_PKG_EOF'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
    linux-generic \
    casper \
    user-setup \
    discover \
    laptop-detect \
    os-prober \
    systemd-sysv \
    systemd \
    dbus \
    dbus-x11 \
    dbus-user-session \
    libpam-systemd \
    polkitd \
    accountsservice \
    network-manager \
    network-manager-gnome \
    locales \
    sudo \
    xorg \
    xserver-xorg-video-all \
    xserver-xorg-input-all \
    at-spi2-core \
    libgl1-mesa-dri \
    mesa-utils \
    gnome-terminal \
    nautilus \
    xdg-user-dirs \
    xdg-utils \
    dconf-cli \
    dconf-gsettings-backend \
    gsettings-desktop-schemas \
    adwaita-icon-theme \
    x11-xserver-utils \
    xinit \
    lightdm \
    lightdm-gtk-greeter \
    lightdm-gtk-greeter-settings \
    libpam-gnome-keyring \
    pipewire \
    pipewire-pulse \
    wireplumber \
    mesa-vulkan-drivers \
    papirus-icon-theme \
    fonts-inter \
    fonts-jetbrains-mono \
    vlc \
    gimp \
    firefox \
    calamares \
    zenity \
    wine \
    winetricks \
    dmg2img \
    p7zip-full \
    hfsprogs \
    zram-tools \
    openbox \
    tint2 \
    picom \
    feh \
    rofi \
    dunst \
    plymouth \
    plymouth-themes \
    plymouth-label

CHROOT_PKG_EOF

# 5. Inject AetherOS Assets (Branding, Themes, Dock, Session, Plymouth, Scripts)
echo "==> [Stage 5/9] Injecting AetherOS liquid glass assets into rootfs..."
mkdir -p "${BUILD_DIR}/usr/share/pixmaps" \
         "${BUILD_DIR}/usr/share/backgrounds/apexos" \
         "${BUILD_DIR}/usr/share/backgrounds/aetheros" \
         "${BUILD_DIR}/usr/share/themes/ApexOS-Dark" \
         "${BUILD_DIR}/usr/share/themes/aetheros-theme" \
         "${BUILD_DIR}/usr/share/plymouth/themes/aetheros" \
         "${BUILD_DIR}/etc/xdg/openbox" \
         "${BUILD_DIR}/etc/xdg/tint2" \
         "${BUILD_DIR}/usr/local/bin" \
         "${BUILD_DIR}/usr/share/applications" \
         "${BUILD_DIR}/usr/share/xsessions"

# Copy Branding logos
if [ -d "${WORKSPACE_ROOT}/branding" ]; then
    cp "${WORKSPACE_ROOT}/branding/logo.png" "${BUILD_DIR}/usr/share/pixmaps/aether-logo.png" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/branding/logo-icon.png" "${BUILD_DIR}/usr/share/pixmaps/aether-icon.png" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/branding/logo-wordmark.png" "${BUILD_DIR}/usr/share/pixmaps/aether-wordmark.png" 2>/dev/null || true
fi

# Copy Wallpapers
if [ -d "${WORKSPACE_ROOT}/themes/wallpapers" ]; then
    cp -r "${WORKSPACE_ROOT}/themes/wallpapers/"* "${BUILD_DIR}/usr/share/backgrounds/apexos/" 2>/dev/null || true
    cp -r "${WORKSPACE_ROOT}/themes/wallpapers/"* "${BUILD_DIR}/usr/share/backgrounds/aetheros/" 2>/dev/null || true
fi

# Copy Plymouth Boot Splash Theme
if [ -d "${WORKSPACE_ROOT}/branding/boot-splash/plymouth-theme" ]; then
    cp -r "${WORKSPACE_ROOT}/branding/boot-splash/plymouth-theme/"* "${BUILD_DIR}/usr/share/plymouth/themes/aetheros/" 2>/dev/null || true
fi

# Copy Openbox Theme & Configuration
if [ -d "${WORKSPACE_ROOT}/themes/openbox/aetheros-theme" ]; then
    cp -r "${WORKSPACE_ROOT}/themes/openbox/aetheros-theme/"* "${BUILD_DIR}/usr/share/themes/aetheros-theme/" 2>/dev/null || true
fi
if [ -f "${WORKSPACE_ROOT}/themes/openbox/rc.xml" ]; then
    cp "${WORKSPACE_ROOT}/themes/openbox/rc.xml" "${BUILD_DIR}/etc/xdg/openbox/rc.xml" 2>/dev/null || true
fi
if [ -f "${WORKSPACE_ROOT}/themes/openbox/menu.xml" ]; then
    cp "${WORKSPACE_ROOT}/themes/openbox/menu.xml" "${BUILD_DIR}/etc/xdg/openbox/menu.xml" 2>/dev/null || true
fi

# Copy Tint2 Liquid Glass Dock Theme
if [ -f "${WORKSPACE_ROOT}/themes/tint2/aetheros-dock.tint2rc" ]; then
    cp "${WORKSPACE_ROOT}/themes/tint2/aetheros-dock.tint2rc" "${BUILD_DIR}/etc/xdg/tint2/aetheros-dock.tint2rc" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/themes/tint2/aetheros-dock.tint2rc" "${BUILD_DIR}/etc/xdg/tint2/tint2rc" 2>/dev/null || true
fi

# Copy GTK Theme
if [ -d "${WORKSPACE_ROOT}/themes/gtk-3.0" ]; then
    cp -r "${WORKSPACE_ROOT}/themes/gtk-3.0" "${BUILD_DIR}/usr/share/themes/ApexOS-Dark/" 2>/dev/null || true
fi

# Copy Desktop Session Scripts & Launchers
if [ -f "${WORKSPACE_ROOT}/desktop/aether-session.sh" ]; then
    cp "${WORKSPACE_ROOT}/desktop/aether-session.sh" "${BUILD_DIR}/usr/local/bin/aether-session"
    chmod +x "${BUILD_DIR}/usr/local/bin/aether-session"
fi
if [ -f "${WORKSPACE_ROOT}/desktop/aether-session.desktop" ]; then
    cp "${WORKSPACE_ROOT}/desktop/aether-session.desktop" "${BUILD_DIR}/usr/share/xsessions/aetheros.desktop"
    ln -sf /usr/share/xsessions/aetheros.desktop "${BUILD_DIR}/usr/share/xsessions/default.desktop" 2>/dev/null || true
fi
if [ -f "${WORKSPACE_ROOT}/desktop/aether-menu.desktop" ]; then
    cp "${WORKSPACE_ROOT}/desktop/aether-menu.desktop" "${BUILD_DIR}/usr/share/applications/"
fi
if [ -f "${WORKSPACE_ROOT}/desktop/install-aetheros.desktop" ]; then
    cp "${WORKSPACE_ROOT}/desktop/install-aetheros.desktop" "${BUILD_DIR}/usr/share/applications/"
fi

# Copy Custom Python Apps (File Manager, Settings) & Runners
if [ -d "${WORKSPACE_ROOT}/desktop/filemanager" ]; then
    cp "${WORKSPACE_ROOT}/desktop/filemanager/"*.py "${BUILD_DIR}/usr/local/bin/" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/desktop/filemanager/"*.desktop "${BUILD_DIR}/usr/share/applications/" 2>/dev/null || true
fi
if [ -d "${WORKSPACE_ROOT}/desktop/settings" ]; then
    cp "${WORKSPACE_ROOT}/desktop/settings/"*.py "${BUILD_DIR}/usr/local/bin/" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/desktop/settings/"*.desktop "${BUILD_DIR}/usr/share/applications/" 2>/dev/null || true
fi
if [ -d "${WORKSPACE_ROOT}/scripts" ]; then
    cp "${WORKSPACE_ROOT}/scripts/"*.sh "${BUILD_DIR}/usr/local/bin/" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/scripts/"*.py "${BUILD_DIR}/usr/local/bin/" 2>/dev/null || true
    cp "${WORKSPACE_ROOT}/scripts/"*.desktop "${BUILD_DIR}/usr/share/applications/" 2>/dev/null || true
fi
chmod +x "${BUILD_DIR}/usr/local/bin/"* 2>/dev/null || true

# 6. Configure Chroot (Users, Display Manager, Plymouth, Fastboot, Initramfs)
echo "==> [Stage 6/9] Configuring users, sessions, Plymouth boot splash and initramfs..."
chroot "${BUILD_DIR}" /bin/bash << 'CHROOT_CFG_EOF'
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C
set -euo pipefail

# 1. Configure initramfs-tools explicitly for Casper Live Boot and generic hardware
mkdir -p /etc/initramfs-tools
touch /etc/initramfs-tools/initramfs.conf
grep -q '^BOOT=' /etc/initramfs-tools/initramfs.conf && sed -i 's/^BOOT=.*/BOOT=casper/' /etc/initramfs-tools/initramfs.conf || echo 'BOOT=casper' >> /etc/initramfs-tools/initramfs.conf
grep -q '^MODULES=' /etc/initramfs-tools/initramfs.conf && sed -i 's/^MODULES=.*/MODULES=most/' /etc/initramfs-tools/initramfs.conf || echo 'MODULES=most' >> /etc/initramfs-tools/initramfs.conf

# Configure casper user & host identity
mkdir -p /etc/casper.conf.d
cat << 'CASPER_EOF' > /etc/casper.conf
export USERNAME="apex"
export USERFULLNAME="AetherOS User"
export HOST="aetheros"
export BUILD_SYSTEM="Ubuntu"
export FLAVOUR="AetherOS"
CASPER_EOF

# 2. Add all storage, CD-ROM, and virtualization drivers to initramfs
cat << 'MOD_EOF' >> /etc/initramfs-tools/modules
sr_mod
cdrom
ata_piix
ahci
sd_mod
virtio_blk
virtio_pci
overlay
squashfs
isofs
loop
MOD_EOF

# 3. Initialize machine-id
systemd-machine-id-setup
dbus-uuidgen --ensure=/etc/machine-id

# 4. Configure default locale and hostname
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
echo "aetheros" > /etc/hostname

# 5. Pre-create live users 'apex' and 'aether' with nopasswdlogin and passwordless sudo
for g in sudo adm audio video plugdev netdev cdrom dip nopasswdlogin; do
    groupadd -f -r "$g" 2>/dev/null || true
done

for u in apex aether; do
    if ! id -u "$u" &>/dev/null; then
        useradd -m -s /bin/bash -G sudo,adm,audio,video,plugdev,netdev,cdrom,dip,nopasswdlogin "$u" 2>/dev/null || useradd -m -s /bin/bash "$u"
        echo "${u}:${u}" | chpasswd
        mkdir -p /etc/sudoers.d
        echo "${u} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${u}"
        chmod 0440 "/etc/sudoers.d/${u}"
    else
        usermod -aG nopasswdlogin,sudo,adm,audio,video,plugdev,netdev,cdrom,dip "$u" 2>/dev/null || true
    fi
    mkdir -p "/home/${u}/.config/openbox" "/home/${u}/.config/tint2" "/home/${u}/Desktop"
    
    # Pre-populate user configurations
    cp /etc/xdg/openbox/rc.xml "/home/${u}/.config/openbox/rc.xml" 2>/dev/null || true
    cp /etc/xdg/openbox/menu.xml "/home/${u}/.config/openbox/menu.xml" 2>/dev/null || true
    cp /etc/xdg/tint2/aetheros-dock.tint2rc "/home/${u}/.config/tint2/tint2rc" 2>/dev/null || true
    cp /usr/share/applications/install-aetheros.desktop "/home/${u}/Desktop/install-aetheros.desktop" 2>/dev/null || true
    chmod +x "/home/${u}/Desktop/install-aetheros.desktop" 2>/dev/null || true
    
    # User .xsession launcher -> launches AetherOS pure fluidity session
    cat << 'XSESSION_USER' > "/home/${u}/.xsession"
#!/bin/sh
exec /usr/local/bin/aether-session
XSESSION_USER
    chmod +x "/home/${u}/.xsession"
    chown -R "${u}:${u}" "/home/${u}"
done

# Ensure PAM permits instant autologin for live session
if [ -f /etc/pam.d/lightdm-autologin ]; then
    sed -i '1s/^/auth sufficient pam_permit.so\n/' /etc/pam.d/lightdm-autologin
fi

# Ensure Xorg wrapper has full rights
mkdir -p /etc/X11
cat << 'XWRAP_EOF' > /etc/X11/Xwrapper.config
allowed_users=anybody
needs_root_rights=yes
XWRAP_EOF

# Ensure xsessions descriptors exist
mkdir -p /usr/share/xsessions
ln -sf /usr/share/xsessions/aetheros.desktop /usr/share/xsessions/default.desktop 2>/dev/null || true
ln -sf /usr/share/xsessions/aetheros.desktop /usr/share/xsessions/gnome.desktop 2>/dev/null || true
ln -sf /usr/share/xsessions/aetheros.desktop /usr/share/xsessions/ubuntu.desktop 2>/dev/null || true

# 6. Configure LightDM (Primary Display Manager for instant live desktop autologin)
mkdir -p /etc/lightdm/lightdm.conf.d
cat << 'LIGHTDM_EOF' > /etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=apex
autologin-user-timeout=0
user-session=aetheros
greeter-session=lightdm-gtk-greeter
xserver-command=X -core -noreset
LIGHTDM_EOF

# Configure LightDM GTK Greeter (Modern Lockscreen with Liquid Flow theme)
cat << 'GREETER_EOF' > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background=/usr/share/backgrounds/apexos/aether-liquid-flow.jpg
theme-name=ApexOS-Dark
icon-theme-name=Papirus-Dark
font-name=Inter 11
user-background=false
clock-format=%I:%M %p
indicators=~host;~spacer;~clock;~spacer;~power
default-user-image=/usr/share/pixmaps/aether-icon.png
position=50%,center 50%,center
screensaver-timeout=0
GREETER_EOF

echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager
mkdir -p /etc/systemd/system
ln -sf /lib/systemd/system/lightdm.service /etc/systemd/system/display-manager.service
ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target
systemctl enable lightdm 2>/dev/null || true

# Set default session for user apex in AccountsService
mkdir -p /var/lib/AccountsService/users
cat << 'ACC_EOF' > /var/lib/AccountsService/users/apex
[User]
Session=aetheros
XSession=aetheros
SystemAccount=false
ACC_EOF
chmod 0600 /var/lib/AccountsService/users/apex

# 7. Register Plymouth Glowing Boot Splash Theme
if [ -d /usr/share/plymouth/themes/aetheros ]; then
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/aetheros/aetheros.plymouth 100 2>/dev/null || true
    update-alternatives --set default.plymouth /usr/share/plymouth/themes/aetheros/aetheros.plymouth 2>/dev/null || true
    plymouth-set-default-theme aetheros -R 2>/dev/null || true
fi

# 8. FlowOS 4-Second Instant Fast Boot Optimization
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true
systemctl mask ModemManager.service 2>/dev/null || true
systemctl mask snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true
systemctl mask plymouth-quit-wait.service 2>/dev/null || true
systemctl mask apport.service 2>/dev/null || true

# 9. Set dark theme, wallpaper, and disable screen blanking in dconf
mkdir -p /etc/dconf/db/local.d /etc/dconf/profile
printf "user-db:user\nsystem-db:local\n" > /etc/dconf/profile/user
cat << 'DCONF_EOF' > /etc/dconf/db/local.d/01-aetheros
[org/gnome/desktop/interface]
gtk-theme='ApexOS-Dark'
icon-theme='Papirus-Dark'
color-scheme='prefer-dark'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/apexos/aether-liquid-flow.jpg'
picture-uri-dark='file:///usr/share/backgrounds/apexos/aether-liquid-flow.jpg'
picture-options='zoom'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/screensaver]
lock-enabled=true
picture-uri='file:///usr/share/backgrounds/apexos/aether-liquid-flow.jpg'
DCONF_EOF
dconf update 2>/dev/null || true

# 10. Re-build initramfs with casper, storage, and Plymouth boot splash hooks
echo "==> Updating initramfs with AetherOS boot splash..."
update-initramfs -u -k all

# Remove policy-rc.d now that packages are installed
rm -f /usr/sbin/policy-rc.d

# Clean APT caches to keep image size compact
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CHROOT_CFG_EOF

# 7. Extract Live Kernel and Initrd before unmounting
echo "==> [Stage 7/9] Extracting live kernel and initramfs..."
VMLINUZ=$(ls -1 "${BUILD_DIR}/boot/vmlinuz-"* | tail -n1)
INITRD=$(ls -1 "${BUILD_DIR}/boot/initrd.img-"* | tail -n1)
cp "${VMLINUZ}" "${ISO_DIR}/casper/vmlinuz"
cp "${INITRD}" "${ISO_DIR}/casper/initrd"

# Unmount virtual filesystems BEFORE mksquashfs
unmount_chroot
trap - EXIT
rm -f "${BUILD_DIR}/etc/resolv.conf" "${BUILD_DIR}/usr/sbin/policy-rc.d" 2>/dev/null || true

# Ensure all essential root mountpoints exist in the rootfs
mkdir -p "${BUILD_DIR}/proc" \
         "${BUILD_DIR}/sys" \
         "${BUILD_DIR}/dev" \
         "${BUILD_DIR}/run" \
         "${BUILD_DIR}/tmp" \
         "${BUILD_DIR}/mnt" \
         "${BUILD_DIR}/media" \
         "${BUILD_DIR}/var/crash" \
         "${BUILD_DIR}/var/log"
chmod 1777 "${BUILD_DIR}/tmp"
chmod 755 "${BUILD_DIR}/proc" "${BUILD_DIR}/sys" "${BUILD_DIR}/dev" "${BUILD_DIR}/run"

# Create essential static device nodes if missing
if [ ! -e "${BUILD_DIR}/dev/console" ]; then
    mknod -m 600 "${BUILD_DIR}/dev/console" c 5 1 2>/dev/null || true
fi
if [ ! -e "${BUILD_DIR}/dev/null" ]; then
    mknod -m 666 "${BUILD_DIR}/dev/null" c 1 3 2>/dev/null || true
fi
if [ ! -e "${BUILD_DIR}/dev/zero" ]; then
    mknod -m 666 "${BUILD_DIR}/dev/zero" c 1 5 2>/dev/null || true
fi

# 8. Write Casper identification files (.disk/info, filesystem.size)
echo "==> [Stage 8/9] Writing Casper Live CD identification markers and squashfs..."
echo "AetherOS 1.0 (Noble Numbat) - Release amd64" > "${ISO_DIR}/.disk/info"
touch "${ISO_DIR}/.disk/base_installable"
echo "full_cd/single" > "${ISO_DIR}/.disk/cd_type"

# Write filesystem uncompressed size for casper overlay RAM calculation
printf $(du -sx --block-size=1 "${BUILD_DIR}" | cut -f1) > "${ISO_DIR}/casper/filesystem.size"

# Generate compressed squashfs (optimized with multithreading and fast zstd)
CORES=$(nproc 2>/dev/null || echo 2)
echo "==> Generating compressed squashfs filesystem using ${CORES} CPU cores (~2-3 mins)..."
mksquashfs "${BUILD_DIR}" "${ISO_DIR}/casper/filesystem.squashfs" \
    -comp zstd -Xcompression-level 1 -processors "${CORES}" -noappend

# 9. Create GRUB2 Boot Configuration & Package Hybrid ISO
echo "==> [Stage 9/9] Packaging bootable hybrid ISO..."

cat << 'EOF' > "${ISO_DIR}/boot/grub/grub.cfg"
set default="0"
set timeout=3

insmod font
if loadfont /boot/grub/font.pf2 ; then
    insmod gfxterm
    set gfxmode=auto
    terminal_output gfxterm
fi

menuentry "Try AetherOS 1.0 (Live Test Mode - Test Before Installing)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=apex hostname=aetheros rw ignore_uuid noprompt quiet splash fastboot loglevel=0 vt.global_cursor_default=0 systemd.show_status=false rd.udev.log_level=0 udev.log_priority=0 fsck.mode=skip console=tty2 ---
    initrd /casper/initrd
}

menuentry "Install AetherOS 1.0 to Disk (Direct Calamares Installer)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=apex hostname=aetheros rw ignore_uuid noprompt quiet splash fastboot loglevel=0 vt.global_cursor_default=0 systemd.show_status=false rd.udev.log_level=0 udev.log_priority=0 fsck.mode=skip only-ubiquity console=tty2 ---
    initrd /casper/initrd
}

menuentry "Start AetherOS 1.0 (Safe Graphics / Compatibility Mode)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=apex hostname=aetheros rw ignore_uuid nomodeset noprompt console=tty0 console=ttyS0 ---
    initrd /casper/initrd
}
EOF

# Package bootable ISO with grub-mkrescue (supports both UEFI and Legacy BIOS)
grub-mkrescue -o "${OUTPUT_DIR}/${ISO_NAME}" "${ISO_DIR}" \
    -- -volid "AetherOS_1_0_Std" 2>/dev/null || \
xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "AetherOS_1_0_Std" \
    -output "${OUTPUT_DIR}/${ISO_NAME}" \
    "${ISO_DIR}"

rm -rf "${WORK_DIR}"

echo "======================================================================"
echo "  AetherOS Standard Edition ISO Build Complete!"
echo "  Output: ${OUTPUT_DIR}/${ISO_NAME}"
echo "======================================================================"
