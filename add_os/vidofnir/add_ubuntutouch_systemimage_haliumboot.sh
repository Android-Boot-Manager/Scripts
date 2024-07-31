#!/system/bin/sh

sed -i "s#replaceme#systempart=/dev/mmcblk1p$4 datapart=/dev/mmcblk1p$5#g" "$BOOTSET/db/entries/$1.conf"

# Add logo
echo "logo $1/logo.bin" >> "$BOOTSET/db/entries/$1.conf"
cp "$3" "$BOOTSET/$1/logo.bin"

# Create working dir
TEMP="$(mktemp -d)"
mkdir -p "$TEMP/boot"

# Copy boot
cp "$2" "$TEMP/boot/boot.img"

# Unpack boot
unpackbootimg -i "$TEMP/boot/boot.img" -o "$TEMP/boot/"

# Format partition
DATAPART=$5
dataformat() {
true | mkfs.ext4 "/dev/block/mmcblk1p$DATAPART"
}
$FORMATDATA && dataformat

# Copy kernel
cp "$TEMP/boot/boot.img-zImage" "$BOOTSET/$1/zImage"

# Copy rd
cp "$TEMP/boot/boot.img-ramdisk.gz" "$BOOTSET/$1/initrd.cpio.gz"