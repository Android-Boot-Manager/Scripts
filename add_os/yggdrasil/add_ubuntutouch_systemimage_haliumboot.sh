#!/system/bin/sh

# Script for installing Ubuntu Touch, with system image and halium boot for ABM. Parameters: ROM folder name, ROM name in menu, system partition number, data partition number, system image path, haliumboot path

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /sdcard/abm/tmp/boot

# Create folder for new OS
mkdir -p "/data/abm/bootset/$1"

# Copy boot
cp "$6" /sdcard/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
cd /sdcard/abm/tmp/boot/ || exit 25
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
cd "$TK" || exit 26

# Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$4"

echo "PLEASE BE PATIENT! This is going to take a long while."

# Write image
dd if="$5" of="/dev/block/mmcblk1p$3"

#Copy dtb
cp /sdcard/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Copy rd
cp haliumrd-sleep10.cpio "/data/abm/bootset/$1/initrd.cpio.gz"

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.selinux=permissive systempart=/dev/mmcblk1p$3 datapart=/dev/mmcblk1p$4
  xsystem    $3
  xdata      $4
  xtype      UT
EOF

# Clean up
#rm -r /sdcard/abm/tmp

echo "Installation done."
