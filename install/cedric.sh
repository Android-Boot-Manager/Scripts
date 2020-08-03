#!/system/bin/sh

# Create working dir
mkdir -p /sdcard/abm

# Backup
dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/abm/stockboot.img

# Flash lk2nd to boot partition
dd if="$1" of=/dev/block/bootdevice/by-name/boot

# Format oem
true | mke2fs /dev/block/bootdevice/by-name/oem

# Mount bootset
mkdir -p /data/bootset
mount -t ext4 /dev/block/bootdevice/by-name/oem /data/bootset

# Create folder for current OS
mkdir -p /data/bootset/lk2nd/entries
mkdir -p "/data/bootset/$2"

mkdir -p /sdcard/abm/temp/boot
./unpackbootimg -i /sdcard/abm/stockboot.img -o /sdcard/abm/temp/boot

# Copy device tree
mkdir -p /sdcard/abm/temp/dt
cp /sys/firmware/fdt "/data/bootset/$2/dtb.dtb"
cp /sys/firmware/fdt /data/bootset/msm8937-motorola-cedric.dtb
cp /sdcard/abm/temp/boot/stockboot.img-dt /sdcard/abm/temp/dt/dt
cwd=$(pwd)
# shellcheck disable=SC2164
cd /sdcard/abm/temp/dt/
"$cwd/dtimgextract" dt
# shellcheck disable=SC2164
cd "$cwd"

#Get current rom DTB
cp /sys/firmware/fdt /sdcard/abm/temp/dt/current.dtb
./dtc -I dtb -O dts -o /sdcard/abm/temp/dt/current.dts /sdcard/abm/temp/dt/current.dtb

#Get board id
bid=$(grep board-id < /sdcard/abm/temp/dt/current.dts)
bid=$(echo "$bid" | awk '{print $4}')
# shellcheck disable=SC2039
bid=${bid:2:4}


#Choose correct dtb
cdtb=$(ls /sdcard/abm/temp/dt/*"$bid"*)
cp "$cdtb" /sdcard/abm/temp/dt/dtb.dtb

#Decompile dtb
./dtc -I dtb -O dts -o /sdcard/abm/temp/dt/dtb.dts /sdcard/abm/temp/dt/dtb.dtb

diff /sdcard/abm/temp/dt/dtb.dts /sdcard/abm/temp/dt/current.dts > /data/bootset/dts.patch

# Copy kernel
cp /sdcard/abm/temp/boot/stockboot.img-zImage "/data/bootset/$2/zImage"

# Copy rd
cp /sdcard/abm/temp/boot/stockboot.img-ramdisk.gz "/data/bootset/$2/initrd.cpio.gz"

# Create entry
cat << EOF >> /data/bootset/lk2nd/lk2nd.conf
   default    Entry 01
   timeout    5
   bgcolor    0x808080
   fcolor     0x000080
   fscolor    0xFFFFFF
   entcolor   0x808080
   entscolor  0x808080
EOF
cat << EOF >> /data/bootset/lk2nd/entries/entry01.conf
  title      $3
  linux      $2/zImage
  initrd     $2/initrd.cpio.gz
  dtb        $2/dtb.dtb
  options    console=null
  xRom       real
  xRomSystem real
  xRomData   real
EOF

# Unmount bootset, and sync cache
umount /data/bootset
sync

# Write meta
cat > /data/abm-part.cfg << EOF
mkdir -p /data/bootset
mount -t ext4 /dev/block/bootdevice/by-name/oem /data/bootset
EOF

cat > /data/abm-part.2.cfg << EOF
umount /data/bootset
EOF

# Clean up
#rm -r /sdcard/abm/temp
