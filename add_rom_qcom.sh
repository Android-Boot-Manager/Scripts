#!/system/bin/sh

# Create working dir
mkdir -p /sdcard/abm
mkdir /sdcard/abm/tmp
mkdir /sdcard/abm/tmp/boot
mkdir /sdcard/abm/tmp/dt

# Mount bootset
mkdir -p /data/bootset
mount -t ext4 /dev/block/bootdevice/by-name/oem /data/bootset

# Create folder for new OS
mkdir -p "/data/bootset/$2"

#Unarchive it
unzip $3 -d /sdcard/abm/tmp/rom

#Copy boot
cp /sdcard/abm/tmp/rom/boot.img /sdcard/abm/tmp/boot

#Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot

#Copy dt
cp /sdcard/abm/tmp/boot/boot.img-dt /sdcard/abm/tmp/dt/dtlz4

#Unarchive dt
lz4 -d /sdcard/abm/tmp/dt/dtlz4 /sdcard/abm/tmp/dt/dt

#Go to dt dir, ectract dtb and go back
cwd=$(pwd)
cd /sdcard/abm/tmp/dt/
$cwd/dtimgextract dt
cd $cwd

