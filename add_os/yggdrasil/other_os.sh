#!/system/bin/sh

# Script for installing other OSes. Parameters: ROM folder name, ROM name in menu, boot path

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /sdcard/abm/tmp/boot

# Create folder for new OS
mkdir -p "/data/abm/bootset/$1"

# Copy boot
cp "$3" /sdcard/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
cd /sdcard/abm/tmp/boot/ || exit 25
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
cd "$TK" || exit 26

#Copy dtb
cp /sdcard/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/abm/bootset/$1/initrd.cpio.gz"

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2
EOF

# Clean up
#rm -r /sdcard/abm/tmp

echo "Installation done."