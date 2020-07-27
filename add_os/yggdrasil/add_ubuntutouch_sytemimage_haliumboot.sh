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
mount /dev/mmcblk1p1 /data/abmmeta

#Get end of last partition
endofpart=$(cat /data/abmmeta/endofparts)

#Add to sfdisk file
echo "start=$(($endofpart + 1)), size=4194304, type=20" >> /data/abmmeta/pt.sfdisk
echo $(($endofpart + 1+4194304)) > /data/abmmeta/endofparts
endofpart=$(cat /data/abmmeta/endofparts)

#Write partition table
sgdisk /dev/mmcblk1 < /data/abmmeta/pt.sfdisk

#Find partition number 
systempart=$(echo $(ls /dev/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
mkfs.ext4 "/dev/mmcblk1p$systempart"

echo "start=$(($endofpart + 1)), size=4194304, type=20" >> /data/abmmeta/pt.sfdisk
echo $(($endofpart + 1+4194304)) > /data/abmmeta/endofparts
endofpart=$(cat /data/abmmeta/endofparts)

#Write partition table
sgdisk /dev/mmcblk1 < /data/abmmeta/pt.sfdisk

#Find partition number 
datapart=$(echo $(ls /dev/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
mkfs.ext4 "/dev/mmcblk1p$datapart"

#write image
dd if="$2" of="/dev/block/mmcblk1p$systempart"

#Copy dtb
dtc -O dtb -o /sdcard/abm/tmp/boot/dtbdump_1.dtb /sdcard/abm/tmp/dtpatch/dtb.dtb

#Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/data/bootset/$2/zImage"

#Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/bootset/$2/initrd.cpio.gz"

echo "systempart=/dev/mmcblk1p$systempart datapart=/dev/mmcblk1p$datapart" >> /sdcard/abm/tmp/boot/boot.img-cmdline
#Create entry
cmdline=$(cat /sdcard/abm/tmp/boot/boot.img-cmdline)
cat << EOF >> /data/bootset/lk2nd/entries/entry"$5".conf
  title      $4
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    $cmdline
EOF

#Clean up
#rm -r /sdcard/abm/tmp
