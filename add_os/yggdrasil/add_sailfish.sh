#!/system/bin/sh

# Script for installing SailfishOS for ABM. Parameters: ROM folder name, boot path, system partition number, vendor partition number, sfos partition number.

TK="/data/data/org.andbootmgr.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /data/abm/tmp/sfos/rd
mkdir -p /data/abm/tmp/boot
mkdir -p /data/abm/mnt

# Copy boot
cp "$2" /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
# shellcheck disable=SC2164
cd /data/abm/tmp/boot/
split-appended-dtb boot.img-zImage
#mv kernel kernel.gz
#gunzip -d kernel.gz
# shellcheck disable=SC2164
cd "$TK"

# Patch ramdisk
(cd /data/abm/tmp/sfos/rd && gunzip -c /data/abm/tmp/boot/boot.img-ramdisk.gz | cpio -i )
cat >/data/abm/tmp/sfos/rd/system_root.mount <<EOF
[Unit]
Description=Droid mount for /system_root
Before=local-fs.target systemd-modules-load.service

[Mount]
What=/dev/mmcblk1p$3
Where=/system_root
Type=ext4
Options=ro
# Options had SELinux context option:

# Default is 90 which makes mount period too long in case of
# errors so drop it down a notch.
TimeoutSec=10

[Install]
WantedBy=local-fs.target

# From ./out/target/product/GS290/vendor/etc/fstab.mt6763 :
# /dev/mmcblk0p31       /           ext4        ro                                                    wait,avb=boot,first_stage_mount
EOF
cat >/data/abm/tmp/sfos/rd/vendor.mount <<EOF
[Unit]
Description=Droid mount for /vendor
Before=local-fs.target systemd-modules-load.service

[Mount]
What=/dev/mmcblk1p$4
Where=/vendor
Type=ext4
Options=ro
# Options had SELinux context option:

# Default is 90 which makes mount period too long in case of
# errors so drop it down a notch.
TimeoutSec=10

[Install]
WantedBy=local-fs.target

# From ./out/target/product/GS290/vendor/etc/fstab.mt6763 :
# /dev/mmcblk0p30       /vendor            ext4        ro                                                    wait,avb,first_stage_mount
EOF
# on purpose:
# shellcheck disable=SC2016
sed -i 's/PHYSDEV=$(find-mmc-bypartlabel "\$label")/sleep 10; PHYSDEV=\/dev\/mmcblk1p'"$5/g" /data/abm/tmp/sfos/rd/sbin/root-mount
sed -i 's/log "Root partition is mounted."/mount --bind \/system_root.mount \/rootfs\/usr\/lib\/systemd\/system\/system_root.mount; mount --bind \/vendor.mount \/rootfs\/usr\/lib\/systemd\/system\/vendor.mount; log "-ABM- Root partition is mounted."/g' /data/abm/tmp/sfos/rd/sbin/root-mount
(cd /data/abm/tmp/sfos/rd && find . | cpio -o -H newc | gzip > "/data/abm/bootset/$1/initrd.cpio.gz")

# Copy dtb
cp /data/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /data/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Clean up
rm -rf /data/abm/tmp
