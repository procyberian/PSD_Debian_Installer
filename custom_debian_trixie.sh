#!/bin/bash

set -e

# Define variables
DEBIAN_VERSION="trixie"   # Updated for Debian 13
ARCH="amd64"
TARGET_DIR="custom-debian"
ISO_NAME="custom-debian-installer.iso"

# Install necessary tools
sudo apt update
sudo apt install -y debootstrap xorriso isolinux syslinux-common squashfs-tools genisoimage wget

# Bootstrap the Debian system
debootstrap --arch=$ARCH $DEBIAN_VERSION $TARGET_DIR http://deb.debian.org/debian/

# Enter the chroot environment and install packages
chroot $TARGET_DIR /bin/bash <<EOF
apt update
apt install -y linux-image-amd64 gcc git
EOF

# Clean up
chroot $TARGET_DIR apt clean

# Download the Debian Installer kernel & initrd for Trixie
mkdir -p $TARGET_DIR/iso/{boot,isolinux}
wget -O $TARGET_DIR/iso/boot/vmlinuz http://deb.debian.org/debian/dists/$DEBIAN_VERSION/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH/linux
wget -O $TARGET_DIR/iso/boot/initrd.gz http://deb.debian.org/debian/dists/$DEBIAN_VERSION/main/installer-$ARCH/current/images/netboot/debian-installer/$ARCH/initrd.gz

# Copy necessary bootloader files
cp /usr/lib/ISOLINUX/isolinux.bin $TARGET_DIR/iso/isolinux/
cp /usr/lib/syslinux/modules/bios/menu.c32 $TARGET_DIR/iso/isolinux/
cp /usr/lib/syslinux/modules/bios/libutil.c32 $TARGET_DIR/iso/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 $TARGET_DIR/iso/isolinux/

# Create an isolinux boot configuration
cat > $TARGET_DIR/iso/isolinux/isolinux.cfg <<EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
LABEL debian-install
  KERNEL /boot/vmlinuz
  APPEND initrd=/boot/initrd.gz
EOF

# Build the ISO
xorriso -as mkisofs \
  -o $ISO_NAME \
  -b isolinux/isolinux.bin \
  -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  $TARGET_DIR/iso

echo "Custom Debian Installer ISO created: $ISO_NAME"
