#!/system/bin/sh

# Script for installing Droidian for ABM. Parameters: ROM folder name, ROM name in menu, data partition number, rootfs zip path, devtools zip path, adaptation zip file

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create working dir
mkdir -p /data/abm/tmp/boot

# Create folder for new OS
mkdir -p "/data/abm/bootset/$1"

# extract adaptation
unzip "$6" -d /data/abm/tmp/adaptation

# extract devtools
unzip "$5" -d /data/abm/tmp/devtools

# Copy boot
cp /data/abm/tmp/adaptation/boot.img /data/abm/tmp/boot/boot.img

# Unpack boot
unpackbootimg -i /data/abm/tmp/boot/boot.img -o /data/abm/tmp/boot/

# Go to dt dir, extract dtb and go back
cd /data/abm/tmp/boot/ || exit 25
split-appended-dtb boot.img-zImage
mv kernel kernel.gz
gunzip -d kernel.gz
cd "$TK" || exit 26

# Format partition
DATAPART=$3
dataformat() {
true | mkfs.ext4 "/dev/block/mmcblk1p$DATAPART"
}

$FORMATDATA && dataformat

#Copy dtb
cp /data/abm/tmp/boot/dtbdump_1.dtb "/data/abm/bootset/$1/dtb.dtb"

# Copy kernel
cp /data/abm/tmp/boot/kernel "/data/abm/bootset/$1/zImage"

# Copy rd
cp haliumrd-sleep10.cpio "/data/abm/bootset/$1/initrd.cpio.gz"

# Mount data partition
mkdir -p /data/abm/tmp/sd
mount "/dev/block/mmcblk1p$DATAPART" /data/abm/tmp/sd -text4

# Copy the rootfs
/sbin/.magisk/busybox/unzip -j "$4" data/rootfs.img -d /data/abm/tmp/sd/

# Resize the rootfs
e2fsck -fy /data/abm/tmp/sd/rootfs.img
resize2fs /data/abm/tmp/sd/rootfs.img 8G

# Mount the rootfs
mkdir -p /data/abm/tmp/r
mount /data/abm/tmp/sd/rootfs.img /data/abm/tmp/r

# Mount Android system
mkdir -p /data/abm/tmp/s
mount /data/abm/tmp/r/var/lib/lxc/android/android-rootfs.img /data/abm/tmp/s

# Generate udev rules
cat /data/abm/tmp/s/ueventd*.rc /vendor/ueventd*.rc | grep ^/dev | sed -e 's/^\/dev\///' | awk '{printf "ACTION==\"add\", KERNEL==\"%s\", OWNER=\"%s\", GROUP=\"%s\", MODE=\"%s\"\n",$1,$3,$4,$2}' | sed -e 's/\r//' > /data/abm/tmp/70-yggdrasil.rules

# Unmount Android system
umount /data/abm/tmp/s

# Move udev rules in place
mv /data/abm/tmp/70-yggdrasil.rules /data/abm/tmp/r/etc/udev/rules.d/70-yggdrasil.rules

# Extract devtools payload
tar -C /data/abm/tmp/r -xf /data/abm/tmp/devtools/payload.tar

# Extract adaptation payload
tar -C /data/abm/tmp/r -xf /data/abm/tmp/adaptation/payload.tar

# Unmount the rootfs
umount /data/abm/tmp/r

# Create a symbolic link for Android system
ln -s /halium-system/var/lib/lxc/android/android-rootfs.img /data/abm/tmp/sd/android-rootfs.img

# Unmount data partition
umount /data/abm/tmp/sd

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/zImage
  initrd     $1/initrd.cpio.gz
  dtb        $1/dtb.dtb
  options    bootopt=64S3,32N2,64N2 androidboot.selinux=permissive datapart=/dev/mmcblk1p$3 ABM.bootloader=1
  xsystem    $3
  xdata      $3
  xtype      UT
EOF

# Clean up
rm -rf /data/abm/tmp

echo "Installation done."
