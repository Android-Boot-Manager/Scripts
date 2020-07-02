#!/system/bin/sh

if [ -b /dev/block/sda ] && [ -b /dev/mmcblk1 ]; then
    echo "both"
elif [ -b /dev/block/sda ]; then
    echo "usb"
elif [ -b /dev/mmcblk1 ]; then
    echo "sd"
else
    echo "none"
fi

