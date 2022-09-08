#!/system/bin/sh

TK="/data/data/org.andbootmgr.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

sed -i "s#replaceme#systempart=/dev/mmcblk1p$3 datapart=/dev/mmcblk1p$4#g" /data/abm/bootset/db/entries/$1.conf

# Create working dir
mkdir -p /data/abm/tmp/boot

# Copy boot
cp "$2" /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Copy kernel
cp /data/abm/tmp/boot/boot.img-zImage "/data/abm/bootset/$1/zImage"

# Copy rd
cp /data/abm/tmp/boot/boot.img-ramdisk.gz "/data/abm/bootset/$1/initrd.cpio.gz" 

# Clean up
rm -rf /data/abm/tmp
