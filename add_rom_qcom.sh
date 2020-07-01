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
unzip "$3" -d /sdcard/abm/tmp/rom

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
"$cwd/dtimgextract" dt
cd "$cwd"

#Get current rom DTB
cp /sys/firmware/fdt /sdcard/abm/tmp/dt/current.dtb
dtc -I dtb -O dts -o /sdcard/abm/tmp/dt/current.dts /sdcard/abm/tmp/dt/current.dtb

#Get board id
bid=$(cat /sdcard/abm/tmp/dt/current.dts | grep board-id)
bid=$(echo "$bid" | awk '{print $4}')
bid=${bid:2:4}
