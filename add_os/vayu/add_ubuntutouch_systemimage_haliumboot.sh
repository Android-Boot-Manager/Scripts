#!/system/bin/sh

TK="/data/data/org.andbootmgr.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

sed -i "s#replaceme#systempart=/dev/mmcblk0p$4 datapart=/dev/mmcblk0p$5#g" /data/abm/bootset/db/entries/"$1".conf

# Copy ut vendor
e2fsck -f /dev/block/mmcblk0p$4
resize2fs /dev/block/mmcblk0p$4
mkdir -p /data/abm/tmp/mnt
mount /dev/block/mmcblk0p$4 /data/abm/tmp/mnt
cp "$3" /data/abm/tmp/mnt/var/lib/lxc/android/vendor.img
umount /data/abm/tmp/mnt

# Create working dir
mkdir -p /data/abm/tmp/boot

# Copy boot
cp "$2" /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
mkdir -p /data/abm/tmp/dt
# shellcheck disable=SC2164
cd /data/abm/tmp/dt/
split-appended-dtb ../boot/boot.img-dtb
# shellcheck disable=SC2164
cd "$TK"

# prepear dtbo
mkdir -p /data/abm/tmp/dtbo
# shellcheck disable=SC2164
cd /data/abm/tmp/dtbo/
split-appended-dtb /dev/block/bootdevice/by-name/dtbo
# shellcheck disable=SC2164
cd "$TK"

# Copy device tree and device tree overlay
dtc -I dtb -O dts -o /data/abm/tmp/dt/current.dts /sys/firmware/fdt
msmidc=$(grep msm-id < /data/abm/tmp/dt/current.dts)
msmidc=$(echo "$msmidc" | awk '{print $4}')
# shellcheck disable=SC3057
msmidc=${msmidc:0:7}
echo "msm-id is $msmidc"

# Fetch abm-board-id from the command line
abm_board_id_arg=$(cat /proc/cmdline | grep -oE 'abm-board-id=[^ ]+' | cut -d= -f2)

# If abm-board-id argument is found, store it in bidc variable
if [ -n "$abm_board_id_arg" ]; then
    bidc=${abm_board_id_arg:0:2}
    echo "board-id is $bidc"
else
    echo "abm-board-id not found in command line."
    exit 1
fi


for f in /data/abm/tmp/dt/dtbdump_*.dtb
do
 dtc -I dtb -O dts -o /data/abm/tmp/dt/test.dts "$f"
 msmidt=$(grep msm-id < /data/abm/tmp/dt/test.dts)
 msmidt=$(echo "$msmidt" | awk '{print $4}')
 # shellcheck disable=SC3057
 msmidt=${msmidt:0:7}
 echo "msmidt $msmidt"
 if [ "$msmidt" = "$msmidc" ]; then
  echo "Found correct dtb $f"
  sed -i '/vendor {/,/};/s/\(\s*status =\).*/\1 "disabled";/'  /data/abm/tmp/dt/test.dts
  dtc -I dts -O dtb -o "/data/abm/bootset/$1/dtb.dtb" /data/abm/tmp/dt/test.dts
 fi
done
if [ ! -f "$f" ]
then
  echo "Dtb not found"
  exit 1
fi

for f in /data/abm/tmp/dtbo/dtbdump_*.dtb
do
 dtc -I dtb -O dts -o /data/abm/tmp/dtbo/test.dts "$f"
 bidt=$(grep board-id < /data/abm/tmp/dtbo/test.dts)
 echo "bidt1 $bidt"
 bidt=$(echo "$bidt" | awk '{print $3}')
 echo "bidt2 $bidt"
 # shellcheck disable=SC3057
 bidt=${bidt:3:4}
 echo "bidt $bidt"
 if [ "$bidc" == "$bidt" ]; then
  echo "Found correct dtbo $f"
  cp "$f" "/data/abm/bootset/$1/dtbo.dtbo"
 fi
done
if [ ! -f "$f" ]
then
  echo "Dtbo not found"
  exit 1
fi

# Copy kernel
cp /data/abm/tmp/boot/boot.img-zImage "/data/abm/bootset/$1/zImage"

# Copy rd
cp /data/abm/tmp/boot/boot.img-ramdisk.gz "/data/abm/bootset/$1/initrd.cpio.gz" 

# Clean up
rm -rf /data/abm/tmp
