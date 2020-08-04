#!/system/bin/sh
PATH=.:$PATH
mkdir -p /data/abmmeta
if [ "$1" = "usb" ]; then
    sgdisk --clear --new=1::32768 --typecode=1:ea00 /dev/block/sda
    blockdev --rereadpt /dev/block/sda; sleep 3
    true | mkfs.ext4 /dev/block/sda1
    mount /dev/block/sda1 /data/abmmeta
elif [ "$1" = "sd" ]; then
    sgdisk --clear --new=1::32768 --typecode=1:ea00 /dev/block/mmcblk1
    blockdev --rereadpt /dev/block/mmcblk1; sleep 3
    true | mkfs.ext4 /dev/block/mmcblk1p1
    mount /dev/block/mmcblk1p1 /data/abmmeta
else
    rm -r /data/abmmeta
    exit 1
fi
touch /data/abmmeta/abm-drive.cfg
umount /data/abmmeta
