#!/system/bin/sh

$BOOTED && exit 0 # only run if bootloader is being installed

# Create folder for current OS
mkdir -p "$BOOTSET/$1"
TEMP="$(mktemp -d)"
mkdir -p "$TEMP/boot"
cp "$BL_BACKUP" "$TEMP/boot/boot.img"
unpackbootimg -i "$TEMP/boot/boot.img" -o "$TEMP/boot/"

CMDLINE="$(cat "$TEMP/boot/boot.img-cmdline")" #TODO
echo "CMDLINE is: $CMDLINE"
sed -i "s#REPLACECMDLINE#${CMDLINE}#g" "$BOOTSET/db/entries/$1.conf"

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
# shellcheck disable=SC3057
msmidc=${msmidc:0:7}
echo "msm-id is $msmidc"
bidc=$(grep board-id < "$TEMP/dt/current.dts")
bidc=$(echo "$bidc" | awk '{print $3}')
# shellcheck disable=SC3057
bidc=${bidc:1:4}
echo "board-id is $bidc"

for f in "$TEMP"/dt/dtbdump_*.dtb
do
 dtc -I dtb -O dts -o "$TEMP/dt/test.dts" "$f"
 msmidt=$(grep msm-id < "$TEMP/dt/test.dts")
 msmidt=$(echo "$msmidt" | awk '{print $4}')
 # shellcheck disable=SC3057
 msmidt=${msmidt:0:7}
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
 bidt=$(echo "$bidt" | awk '{print $3}')
 # shellcheck disable=SC3057
 bidt=${bidt:1:4}
 if [ "$bidt" = "$bidc" ]; then
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
cp "$TEMP/boot/boot.img-zImage" "$BOOTSET/$1/kernel"

# Copy rd
cp "$TEMP/boot/boot.img-ramdisk.gz" "$BOOTSET/$1/initrd.cpio.gz"
