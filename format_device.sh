#!/system/bin/sh

mkdir /data/abmmeta
if [ "$1" = "usb" ]; then
    sfdisk /dev/block/sda < partition_table.sfdisk
    mkfs.ext4 /dev/block/sda1
    mount /dev/block/sda1 /data/abmmeta
elif [ "$1" = "sd" ]; then
    sfdisk /dev/mmcblk1 < partition_table.sfdisk
    mkfs.ext4 /dev/mmcblk1p1
    mount /dev/mmcblk1p1 /data/abmmeta
else
    rm -r /data/abmmeta
    exit 1
fi
echo "34816" > /data/abmmeta/endofparts
cp partition_table.sfdisk /data/abmmeta/pt.sfdisk
touch /data/abmmeta/abm-drive.cfg
umount /data/abmmeta
