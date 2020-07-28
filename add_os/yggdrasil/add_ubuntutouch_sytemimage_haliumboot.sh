#!/system/bin/sh

# Script for installing Ubuntu Touch, with system image and halium boot for ABM. Parametrs: ROM folder name, system image path, haliumboot path,
# ROM name in menu, entry number.

PATH=.:$PATH
# Create working dir
mkdir -p /sdcard/abm
mkdir -p /sdcard/abm/tmp
mkdir -p /sdcard/abm/tmp/boot

# Create folder for new OS
mkdir -p "/data/bootset/$1"

#Copy boot
cp "$3" /sdcard/abm/tmp/boot/boot.img

#Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot/

#Go to dt dir, ectract dtb and go back
cwd=$(pwd)
# shellcheck disable=SC2164
cd /sdcard/abm/tmp/boot/
"$cwd/split-appended-dtb" boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
# shellcheck disable=SC2164
cd "$cwd"

#Mount metadata
mount /dev/block/mmcblk1p1 /data/abmmeta

#Get end of last partition
endofpart=$(cat /data/abmmeta/endofparts)


#Write partition table
sgdisk --new=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):$(($endofpart + 1)):+7340032 /dev/block/mmcblk1

#Modify endofpart
echo $(($endofpart + 1+7340032)) > /data/abmmeta/endofparts
endofpart=$(cat /data/abmmeta/endofparts)

#Umount abmmeta and sync pt
umount /data/abmmeta
blockdev --rereadpt /dev/block/mmcblk1; sleep 3

#Find partition number 
systempart=$(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$systempart"

#Write partition table
sgdisk --new=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):$(($endofpart + 1)):+4194304 /dev/block/mmcblk1

#Umount abmmeta and sync pt
umount /data/abmmeta
blockdev --rereadpt /dev/block/mmcblk1; sleep 3
mount /dev/block/mmcblk1p1 /data/abmmeta

#Modify endofpart
echo $(($endofpart + 1+4194304)) > /data/abmmeta/endofparts

#Find partition number 
datapart=$(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$datapart"

#write image
dd if="$2" of="/dev/block/mmcblk1p$systempart"

#Copy dtb
cp /sdcard/abm/tmp/boot/dtbdump_1.dtb "/data/bootset/$1/dtb.dtb"

#Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/data/bootset/$1/zImage"

#Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/bootset/$1/initrd.cpio.gz"

#Create entry
cat << EOF >> /data/bootset/db/entries/entry"$5".conf
  title      $4
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.seliux=permissive systempart=/dev/mmcblk1p$systempart datapart=/dev/mmcblk1p$datapart 
EOF

#Clean up
#rm -r /sdcard/abm/tmp
