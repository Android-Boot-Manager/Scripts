#!/system/bin/sh

# Backup
dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/abm/stockboot.img

# Flash lk2nd to boot partition
dd if=/data/data/org.androidbootmanager.app/files/lk2nd.img of=/dev/block/bootdevice/by-name/boot

# Mount bootset
mkdir -p /data/bootset
mount -t ext4 /dev/block/bootdevice/by-name/oem /data/bootset

mkdir -p /sdcard/abm/temp/boot
./unpackbootimg -i /sdcard/abm/stockboot.img -o /sdcard/abm/temp/boot

# Copy device tree
cp /sys/firmware/fdt "/data/bootset/hjacked/dtb.dtb"

# Copy kernel
cp /sdcard/abm/temp/boot/stockboot.img-zImage "/data/bootset/hjacked/zImage"

# Copy rd
cp /sdcard/abm/temp/boot/stockboot.img-ramdisk.gz "/data/bootset/hjacked/initrd.cpio.gz"
