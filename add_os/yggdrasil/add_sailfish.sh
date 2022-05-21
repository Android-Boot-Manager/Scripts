#!/system/bin/sh

# Script for installing SailfishOS for ABM. Parameters: ROM folder name, ROM name in menu, system partition number, hybris-boot path.

TK="/data/data/org.andbootmgr.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /data/abm/tmp/sfos/rd
mkdir -p /data/abm/tmp/boot
mkdir -p /data/abm/mnt

# Copy boot
cp "$4" /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
# shellcheck disable=SC2164
cd /data/abm/tmp/boot/
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
# shellcheck disable=SC2164
cd "$TK"

mkdir "/data/abm/bootset/$1"

# Patch ramdisk
(cd /data/abm/tmp/sfos/rd && gunzip -c /data/abm/tmp/boot/boot.img-ramdisk.gz | cpio -i )
# This is not supposed to be executed, ShellCheck.
# shellcheck disable=SC2016
sed -i 's/PHYSDEV=$(find-mmc-bypartlabel "\$label")/sleep 10; PHYSDEV=\/dev\/mmcblk1p'"$3/g" /data/abm/tmp/sfos/rd/sbin/root-mount
(cd /data/abm/tmp/sfos/rd && find . | cpio -o -H newc | gzip > "/data/abm/bootset/$1/initrd.cpio.gz")

# Copy dtb
cp /data/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /data/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.selinux=permissive
  xsystem $3
  xtype SFOS
EOF

# Clean up
rm -rf /data/abm/tmp
