#!/system/bin/sh

# Script for installing Ubuntu Touch, with system image and halium boot for ABM. Parametrs: ROM folder name, system image path, haliumboot path,
# ROM name in menu, entry number.

PATH=.:$PATH
# Create working dir
mkdir -p /sdcard/abm
mkdir -p /sdcard/abm/tmp
mkdir -p /sdcard/abm/tmp/boot
mkdir -p /sdcard/abm/tmp/sfos/rd
mkdir -p /data/abm/mnt

#Unpack zip
unzip "$2" -d /sdcard/abm/tmp/sfos/

#Copy boot
cp /sdcard/abm/tmp/sfos/hybris-boot.img /sdcard/abm/tmp/boot/boot.img

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
umount /data/abmmeta


#Write partition table
# shellcheck disable=SC2012
sgdisk --new=0::+7340032 /dev/block/mmcblk1

#sync pt
blockdev --rereadpt /dev/block/mmcblk1; sleep 3

#Find partition number 
# shellcheck disable=SC2012
systempart=$(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$systempart"

#Extract rootfs
mount "/dev/block/mmcblk1p$systempart" /data/abm/mnt
mkdir -p /data/abm/mnt/.stowaways/sailfishos
tar --numeric-owner -xvjf /sdcard/abm/tmp/sfos/*.tar.bz2 -C /data/abm/mnt/.stowaways/sailfishos
umount /data/abm/mnt

ENTRYNUM=`find /cache/db/entries -name "entry*" | wc -l`
ENTRYNUM=$((ENTRYNUM+1))

mkdir "/cache/$ENTRYNUM"

#Patch ramdisk
(cd /sdcard/abm/tmp/sfos/rd && gunzip -c /sdcard/abm/tmp/boot/boot.img-ramdisk.gz | cpio -i )
sed -i "/DATA_PARTITION=/c\DATA_PARTITION=/dev/mmcblk1p$systempart" /sdcard/abm/tmp/sfos/rd/init
(cd /sdcard/abm/tmp/sfos/rd && find . | cpio -o -H newc | gzip > "/cache/$ENTRYNUM/initrd.cpio.gz")


#Copy dtb
cp /sdcard/abm/tmp/boot/dtbdump_1.dtb "/cache/$ENTRYNUM/dtb.dtb"

#Copy kernel
cp /sdcard/abm/tmp/boot/kernel "/cache/$ENTRYNUM/zImage"

#Create entry
cat << EOF >> /cache/db/entries/entry"$ENTRYNUM".conf
  title      $1
  linux      $ENTRYNUM/zImage
  initrd     $ENTRYNUM/initrd.cpio.gz
  dtb        $ENTRYNUM/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.seliux=permissive systempart=/dev/mmcblk1p$systempart datapart=/dev/mmcblk1p$datapart 
EOF

#Clean up
#rm -r /sdcard/abm/tmp
