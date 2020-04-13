#!/system/bin/sh

check=$(strings /dev/block/bootdevice/by-name/boot | grep lk2nd)
[ -z "$check" ] && exit 1 || exit 0
