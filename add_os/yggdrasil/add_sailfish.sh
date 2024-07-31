#!/system/bin/sh

# Create working dir
TEMP="$(mktemp -d install)"
mkdir -p "$TEMP/sfos/rd"
mkdir -p "$TEMP/boot"
mkdir -p "$TEMP/mnt"

# Copy boot
cp "$2" "$TEMP/boot/boot.img"

# Unpack boot
unpackbootimg -i "$TEMP/boot/boot.img" -o "$TEMP/boot/"

# Go to dt dir, extract dtb and go back
cd "$TEMP/boot/" || exit 1
split-appended-dtb boot.img-zImage
cd "$TK" || exit 1

# Patch ramdisk
(cd "$TEMP/sfos/rd" && gunzip -c "$TEMP/boot/boot.img-ramdisk.gz" | cpio -i )
#cat >"$TEMP/sfos/rd/system_root.mount" <<EOF
#[Unit]
#Description=Droid mount for /system_root
#Before=local-fs.target systemd-modules-load.service
#
#[Mount]
#What=/dev/mmcblk1p$4
#Where=/system_root
#Type=ext4
#Options=ro
## Options had SELinux context option:
#
## Default is 90 which makes mount period too long in case of
## errors so drop it down a notch.
#TimeoutSec=10
#
#[Install]
#WantedBy=local-fs.target
#
## From ./out/target/product/GS290/vendor/etc/fstab.mt6763 :
## /dev/mmcblk0p31       /           ext4        ro                                                    wait,avb=boot,first_stage_mount
#EOF
#cat >"$TEMP/sfos/rd/vendor.mount" <<EOF
#[Unit]
#Description=Droid mount for /vendor
#Before=local-fs.target systemd-modules-load.service
#
#[Mount]
#What=/dev/mmcblk1p$3
#Where=/vendor
#Type=ext4
#Options=ro
## Options had SELinux context option:
#
## Default is 90 which makes mount period too long in case of
## errors so drop it down a notch.
#TimeoutSec=10
#
#[Install]
#WantedBy=local-fs.target
#
## From ./out/target/product/GS290/vendor/etc/fstab.mt6763 :
## /dev/mmcblk0p30       /vendor            ext4        ro                                                    wait,avb,first_stage_mount
#EOF
# on purpose:
# shellcheck disable=SC2016
sed -i 's/PHYSDEV=$(find-mmc-bypartlabel "\$label")/sleep 10; PHYSDEV=\/dev\/mmcblk1p'"$5/g" "$TEMP/sfos/rd/sbin/root-mount"
#sed -i 's/log "Root partition is mounted."/mount --bind \/system_root.mount \/rootfs\/usr\/lib\/systemd\/system\/system_root.mount; mount --bind \/vendor.mount \/rootfs\/usr\/lib\/systemd\/system\/vendor.mount; log "-ABM- Root partition is mounted."/g' "$TEMP/sfos/rd/sbin/root-mount"
(cd "$TEMP/sfos/rd" && find . | cpio -o -H newc | gzip > "$BOOTSET/$1/initrd.cpio.gz")

# Copy dtb
cp "$TEMP/boot/dtbdump_1.dtb" "$BOOTSET/$1/dtb.dtb"

# Copy kernel
cp "$TEMP/boot/kernel" "$BOOTSET/$1/zImage"