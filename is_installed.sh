#!/system/bin/sh

check=$(strings /dev/block/bootdevice/by-name/boot | grep lk2nd)
[ -z "$check" ] && exit 0 || exit 1
