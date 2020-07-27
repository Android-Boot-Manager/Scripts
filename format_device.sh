#!/system/bin/sh
PATH=.:$PATH
mkdir -p /data/abmmeta
if [ "$1" = "usb" ]; then
    sgdisk /dev/block/sda < ../Scripts/partition_table.sfdisk
    partprobe; sleep 3
    true | mkfs.ext4 /dev/block/sda1
    mount /dev/block/sda1 /data/abmmeta
elif [ "$1" = "sd" ]; then
    sgdisk /dev/block/mmcblk1 < ../Scripts/partition_table.sfdisk
    partprobe; sleep 3
    true | mkfs.ext4 /dev/block/mmcblk1p1
    mount /dev/block/mmcblk1p1 /data/abmmeta
else
    rm -r /data/abmmeta
    exit 1
fi
echo "34816" > /data/abmmeta/endofparts
cp ../Scripts/partition_table.sfdisk /data/abmmeta/pt.sfdisk
touch /data/abmmeta/abm-drive.cfg
umount /data/abmmeta
