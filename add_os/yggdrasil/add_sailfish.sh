#!/system/bin/sh

# Script for installing SailfishOS for ABM. Parameters: ROM folder name, ROM name in menu, system partition number, zip file path.

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /sdcard/abm
mkdir -p /sdcard/abm/tmp
mkdir -p /sdcard/abm/tmp/boot
mkdir -p /sdcard/abm/tmp/sfos/rd
mkdir -p /data/abm/mnt

# Unpack zip
unzip "$4" -d /sdcard/abm/tmp/sfos/

# Copy boot
cp /sdcard/abm/tmp/sfos/hybris-boot.img /sdcard/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
# shellcheck disable=SC2164
cd /sdcard/abm/tmp/boot/
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
# shellcheck disable=SC2164
cd "$TK"

# Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$3"

# Extract rootfs
mount "/dev/block/mmcblk1p$3" /data/abm/mnt
mkdir -p /data/abm/mnt/.stowaways/sailfishos
tar --numeric-owner -xvjf /sdcard/abm/tmp/sfos/*.tar.bz2 -C /data/abm/mnt/.stowaways/sailfishos
umount /data/abm/mnt

mkdir "/data/abm/bootset/$1"

# Patch ramdisk
(cd /sdcard/abm/tmp/sfos/rd && gunzip -c /sdcard/abm/tmp/boot/boot.img-ramdisk.gz | cpio -i )
sed -i "/DATA_PARTITION=/c\DATA_PARTITION=/dev/mmcblk1p$3" /sdcard/abm/tmp/sfos/rd/init
(cd /sdcard/abm/tmp/sfos/rd && find . | cpio -o -H newc | gzip > "/data/abm/bootset/$1/initrd.cpio.gz")

# Copy dtb
cp /sdcard/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.selinux=permissive
  xsystem $3
  xdata SFOS
EOF

# Clean up
#rm -r /sdcard/abm/tmp
