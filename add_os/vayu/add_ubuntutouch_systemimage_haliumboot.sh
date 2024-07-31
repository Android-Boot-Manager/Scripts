#!/system/bin/sh

sed -i "s#replaceme#systempart=/dev/mmcblk0p$4 datapart=/dev/mmcblk0p$5#g" "$BOOTSET/db/entries/$1.conf"

# Copy ut vendor
e2fsck -f "/dev/block/mmcblk0p$4"
resize2fs "/dev/block/mmcblk0p$4"
TEMP="$(mktemp -d install.XXX)"
mkdir -p "$TEMP/mnt"
mount "/dev/block/mmcblk0p$4" "$TEMP/mnt"
cp "$3" "$TEMP/mnt/var/lib/lxc/android/vendor.img"
umount "$TEMP/mnt"

# Create working dir
mkdir -p "$TEMP/boot"

# Copy boot
cp "$2" "$TEMP/boot/boot.img"

# Unpack boot
unpackbootimg -i "$TEMP/boot/boot.img" -o "$TEMP/boot/"

# Go to dt dir, extract dtb and go back
mkdir -p "$TEMP/dt"
cd "$TEMP/dt/" || exit 1
split-appended-dtb "$TEMP/boot/boot.img-dtb"
cd "$TK" || exit 1

# prepare dtbo
mkdir -p "$TEMP/dtbo"
cd "$TEMP/dtbo/" || exit 1
split-appended-dtb /dev/block/bootdevice/by-name/dtbo
cd "$TK" || exit 1

# Copy device tree and device tree overlay
dtc -I dtb -O dts -o "$TEMP/dt/current.dts" /sys/firmware/fdt
msmidc=$(grep msm-id < "$TEMP/dt/current.dts")
msmidc=$(echo "$msmidc" | awk '{print $4}')
# shellcheck disable=SC2039
msmidc=${msmidc:0:7}
echo "msm-id is $msmidc"

# Fetch abm-board-id from the command line
abm_board_id_arg=$(grep -oE 'abm-board-id=[^ ]+' /proc/cmdline | cut -d= -f2)

# If abm-board-id argument is found, store it in bidc variable
if [ -n "$abm_board_id_arg" ]; then
	# shellcheck disable=SC3057
    bidc=${abm_board_id_arg:0:2}
    echo "board-id is $bidc"
else
    echo "abm-board-id not found in command line."
    exit 1
fi


for f in "$TEMP"/dt/dtbdump_*.dtb
do
 dtc -I dtb -O dts -o "$TEMP/dt/test.dts" "$f"
 msmidt=$(grep msm-id < "$TEMP/dt/test.dts")
 msmidt=$(echo "$msmidt" | awk '{print $4}')
 # shellcheck disable=SC3057
 msmidt=${msmidt:0:7}
 echo "msmidt $msmidt"
 if [ "$msmidt" = "$msmidc" ]; then
  echo "Found correct dtb $f"
  sed -i '/vendor {/,/};/s/\(\s*status =\).*/\1 "disabled";/' "$TEMP/dt/test.dts"
  dtc -I dts -O dtb -o "$BOOTSET/$1/dtb.dtb" "$TEMP/dt/test.dts"
 fi
done
if [ ! -f "$f" ]
then
  echo "Dtb not found"
  exit 1
fi

for f in "$TEMP"/dtbo/dtbdump_*.dtb
do
 dtc -I dtb -O dts -o "$TEMP/dtbo/test.dts" "$f"
 bidt=$(grep board-id < "$TEMP/dtbo/test.dts")
 echo "bidt1 $bidt"
 bidt=$(echo "$bidt" | awk '{print $3}')
 echo "bidt2 $bidt"
 # shellcheck disable=SC3057
 bidt=${bidt:3:4}
 echo "bidt $bidt"
 if [ "$bidc" == "$bidt" ]; then
  echo "Found correct dtbo $f"
  cp "$f" "$BOOTSET/$1/dtbo.dtbo"
 fi
done
if [ ! -f "$f" ]
then
  echo "Dtbo not found"
  exit 1
fi

# Copy kernel
cp "$TEMP/boot/boot.img-zImage" "$BOOTSET/$1/zImage"

# Copy rd
cp "$TEMP/boot/boot.img-ramdisk.gz" "$BOOTSET/$1/initrd.cpio.gz"