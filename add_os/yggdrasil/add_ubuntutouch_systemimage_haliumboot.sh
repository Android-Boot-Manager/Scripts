#!/system/bin/sh

# Script for installing Ubuntu Touch, with system image and halium boot for ABM. Parameters: ROM folder name, ROM name in menu, system partition number, data partition number, haliumboot path

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /data/abm/tmp/boot

# Create folder for new OS
mkdir -p "/data/abm/bootset/$1"

# Copy boot
cp "$5" /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
cd /data/abm/tmp/boot/ || exit 25
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
cd "$TK" || exit 26

# Format partition
DATAPART=$4
dataformat() {
true | mkfs.ext4 "/dev/block/mmcblk1p$DATAPART"
}

$FORMATDATA && dataformat

#Copy dtb
cp /data/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /data/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

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
rm -rf /data/abm/tmp

echo "Installation done."
