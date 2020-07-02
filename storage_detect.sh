#!/system/bin/sh

if [ -b /dev/block/sda ] && [ -b /dev/block/mmcblk1 ]; then
    echo "both"
elif [ -b /dev/block/sda ]; then
    echo "usb"
elif [ -b /dev/block/mmcblk1 ]; then
    echo "sd"
else
    echo "none"
fi

