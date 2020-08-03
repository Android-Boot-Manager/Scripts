#!/system/bin/sh

# Script for installing Ubuntu Touch, with system image and halium boot for ABM. Parametrs: ROM folder name, system image path, haliumboot path,
# ROM name in menu, entry number, rootfs.

PATH=.:$PATH
# Create working dir
mkdir -p /sdcard/abm
mkdir -p /sdcard/abm/tmp
mkdir -p /sdcard/abm/tmp/boot
mkdir -p /sdcard/abm/tmp/dt
mkdir -p /sdcard/abm/tmp/dtpatch
mkdir -p /data/abm/mnt

# Create folder for new OS
mkdir -p "/data/bootset/$1"

#Copy boot
cp "$3" /sdcard/abm/tmp/boot/boot.img

#Unpack boot
unpackbootimg -i /sdcard/abm/tmp/boot/boot.img -o /sdcard/abm/tmp/boot/

#Copy dt
cp /sdcard/abm/tmp/boot/boot.img-dt /sdcard/abm/tmp/dt/dtlz4
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

#Mount metadata
mount /dev/block/mmcblk1p1 /data/abmmeta

#Get end of last partition
endofpart=$(cat /data/abmmeta/endofparts)

#Write partition table
# shellcheck disable=SC2012
sgdisk --new=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):$(($endofpart + 1)):+7340032 --typecode=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):8305 /dev/block/mmcblk1

#Modify endofpart
echo $((endofpart + 1+7340032)) > /data/abmmeta/endofparts
endofpart=$(cat /data/abmmeta/endofparts)

#Umount abmmeta and sync pt
umount /data/abmmeta
blockdev --rereadpt /dev/block/mmcblk1; sleep 3

#Find partition number 
# shellcheck disable=SC2012
systempart=$(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')

#Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$systempart"

#Write partition table
# shellcheck disable=SC2012
sgdisk --new=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):$(($endofpart + 1)):+4194304 --typecode=$(($(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')+1)):8302 /dev/block/mmcblk1

#sync pt
blockdev --rereadpt /dev/block/mmcblk1; sleep 3
mount /dev/block/mmcblk1p1 /data/abmmeta

#Modify endofpart
echo $((endofpart + 1+4194304)) > /data/abmmeta/endofparts

#Find partition number 
# shellcheck disable=SC2012
datapart=$(echo $(ls /dev/block/mmcblk1p*) | sed 's/ //g' | grep -Eo '[0-9]+$')


#Format partition
true | mkfs.ext4 "/dev/block/mmcblk1p$datapart"

#mount partition
mount "/dev/block/mmcblk1p$systempart" /data/abm/mnt

#write image
tar -xvf "$6" -C /data/abm/mnt
cp "$2" /data/abm/mnt/var/lib/lxc/android/system.img

# halium postinstall
touch /data/abm/mnt/home/phablet/.display-mir
sed -i 's/PasswordAuthentication=no/PasswordAuthentication=yes/g' "/data/abm/mnt/etc/init/ssh.override"
sed -i 's/manual/start on startup/g' "/data/abm/mnt/etc/init/ssh.override"
sed -i 's/manual/start on startup/g' "/data/abm/mnt/etc/init/usb-tethering.conf"
mkdir -p "/data/abm/mnt/android/firmware"
mkdir -p "/data/abm/mnt/android/persist"
mkdir -p "/data/abm/mnt/userdata"
for link in cache data factory firmware persist system odm product metadata vendor; do ln -s /android/$link "/data/abm/mnt/$link"; done
ln -s /system/lib/modules "/data/abm/mnt/lib/modules"
rm -f "/data/abm/mnt/etc/mtab"
ln -s /proc/mounts "/data/abm/mnt/etc/mtab"

umount /data/abm/mnt

#Copy dtb
cp /sdcard/abm/tmp/dtpatch/dtb.dtb "/data/bootset/$1/dtb.dtb"

#Copy kernel
cp /sdcard/abm/tmp/boot/boot.img-zImage "/data/bootset/$1/zImage"

#Copy rd
cp /sdcard/abm/tmp/boot/boot.img-ramdisk.gz "/data/bootset/$1/initrd.cpio.gz"

#Create entry
cat << EOF >> /data/bootset/lk2nd/entries/entry"$5".conf
  title      $4
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    androidboot.selinux=permissive systempart=/dev/mmcblk1p$systempart datapart=/dev/mmcblk1p$datapart console=tty0
EOF

#Clean up
#rm -r /sdcard/abm/tmp
