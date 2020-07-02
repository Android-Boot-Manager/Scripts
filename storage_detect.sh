#!/system/bin/sh

if [ ! -f /dev/block/sda ] && [ ! -f /dev/mmcblk1 ]; then
    echo "both"
elif [ ! -f /dev/block/sda ]; then
    echo "usb"
elif [ ! -f /dev/mmcblk1 ]; then
    echo "sd"
else
    echo "none"
fi

