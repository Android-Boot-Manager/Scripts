#!/system/bin/sh

CMDLINE="console=null" #TODO
sed -i "s#REPLACECMDLINE#${CMDLINE}#g" "/data/abm/bootset/db/entries/$1.conf"

# Create folder for current OS
mkdir -p "/data/abm/bootset/$1"

mkdir -p /data/abm/tmp/boot
cp /data/abm/backup_lk.img /data/abm/tmp/boot/boot.img
./unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Copy device tree
cp /sys/firmware/fdt "/data/abm/bootset/$1/dtb.dtb"
cp /sys/firmware/fdt /data/abm/bootset/msm8937-motorola-cedric.dtb

# Copy kernel
cp /data/abm/tmp/boot/boot.img-zImage "/data/abm/bootset/$1/kernel"

# Copy rd
cp /data/abm/tmp/boot/boot.img-ramdisk.gz "/data/abm/bootset/$1/initrd.cpio.gz"
