#!/system/bin/sh

# Script for installing ROM zip, with halium's system image and halium boot for ABM. Parametrs: ROM folder name, rom zip, idk,
# ROM name in menu, entry number.

PATH=.:$PATH
# Create working dir
mkdir /sdcard/abm
mkdir /sdcard/abm/tmp
mkdir /sdcard/abm/tmp/boot
mkdir /sdcard/abm/tmp/dt
mkdir /sdcard/abm/tmp/dtpatch

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
bid=$(grep board-id < /sdcard/abm/tmp/dt/current.dts)
bid=$(echo "$bid" | awk '{print $4}')
# shellcheck disable=SC2039
bid=${bid:2:4}

#Choose correct dtb
cdtb=$(ls /sdcard/abm/tmp/dt/*"$bid"*)
cp "$cdtb" /sdcard/abm/tmp/dtpatch/dtb.dtb

#Decompile dtb
dtc -I dtb -O dts -o /sdcard/abm/tmp/dtpatch/dtb.dts /sdcard/abm/tmp/dtpatch/dtb.dtb

#Mount metadata
mount /dev/mmcblk1p1 /data/abmmeta

#Get end of last partition
endofpart=$(cat /data/abmmeta/endofparts)

#Add to sfdisk file
echo "start=$(($endofpart + 1)), size=4194304, type=20" >> /data/abmmeta/pt.sfdisk

#Write partition table
sgdisk /dev/mmcblk1 < /data/abmmeta/pt.sfdisk

#Find partition number 
systempart=$(echo $(ls /dev/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
mkfs.ext4 "/dev/mmcblk1p$systempart"

#Patch dts
sed -i "s/\/dev\/block\/platform\/soc\/7824900.sdhci\/by-name\/system/\/dev\/block\/platform\/soc\/7864900.sdhci\/mmcblk1p$systempart/g" /sdcard/abm/tmp/dtpatch/dtb.dts 

#Compile dts
dtc -O dtb -o "/data/bootset/$2/dtb.dtb" /sdcard/abm/tmp/dtpatch/dtb.dts

#Copy kernel
cp /sdcard/abm/tmp/boot/boot.img-zImage "/data/bootset/$2/zImage"

#Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/bootset/$2/initrd.cpio.gz"

#Create entry
cmdline=$(cat /sdcard/abm/tmp/boot/boot.img-cmdline)
cat << EOF >> /data/bootset/lk2nd/entries/entry"$5".conf
  title      $4
  linux      $2/zImage
  initrd     $2/initrd.cpio.gz
  dtb        $2/dtb.dtb
  options    $cmdline
EOF

#Clean up
rm -r /sdcard/abm/tmp

#Unmount bootset 
umount /data/bootset
