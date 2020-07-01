#!/system/bin/sh

# Create working dir
mkdir /sdcard/abm
mkdir /sdcard/abm/tmp
mkdir /sdcard/abm/tmp/boot
mkdir /sdcard/abm/tmp/dt
mkdir /sdcard/abm/tmp/dtpatch

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
# shellcheck disable=SC2164
cd /sdcard/abm/tmp/dt/
"$cwd/dtimgextract" dt
# shellcheck disable=SC2164
cd "$cwd"

#Get current rom DTB
cp /sys/firmware/fdt /sdcard/abm/tmp/dt/current.dtb
dtc -I dtb -O dts -o /sdcard/abm/tmp/dt/current.dts /sdcard/abm/tmp/dt/current.dtb

#Get board id
bid=$(cmd /sdcard/abm/tmp/dt/current.dts | grep board-id)
bid=$(echo "$bid" | awk '{print $4}')
# shellcheck disable=SC2039
bid=${bid:2:4}

#Choose correct dtb
cdtb=$(ls /sdcard/abm/tmp/dt/*"$bid"*)
cp "$cdtb" /sdcard/abm/tmp/dtpatch/dtb.dtb

#Decompile dtb
dtc -I dtb -O dts -o /sdcard/abm/tmp/dtpatch/dtb.dts /sdcard/abm/tmp/dtpatch/dtb.dtb

#Patch dts
sed -i "s/\/dev\/block\/platform\/soc\/7824900.sdhci\/by-name\/system/\/dev\/block\/platform\/soc\/7864900.sdhci\/$4/g" /sdcard/abm/tmp/dtpatch/dtb.dts 

#Compile dts
dtc -O dtb -o "/data/bootset/$2/dtb.dtb" /sdcard/abm/tmp/dtpatch/dtb.dts

#Copy kernel
cp /sdcard/abm/tmp/boot/boot.img-zImage "/data/bootset/$2/zImage"

#Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/bootset/$2/initrd.cpio.gz"

#Create entry
cmdline=$(cat /sdcard/abm/tmp/boot/boot.img-cmdline)
cat << EOF >> /data/bootset/lk2nd/entries/entry"$6".conf
  title      $5
  linux      $2/zImage
  initrd     $2/initrd.cpio.gz
  dtb        $2/dtb.dtb
  options    $cmdline
EOF

#Clean up
rm -r /sdcard/abm/tmp

#Unmount bootset 
umount /data/bootset
