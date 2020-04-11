# Create working dir
mkdir -p /sdcard/abm

# Backup
dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/abm/stockboot.img

# Flash lk2nd to boot partition
dd if=$1 of=/dev/block/bootdevice/by-name/boot

# Mount bootset
mkdir -p /data/bootset
mount /dev/block/mmcblk0p51 /data/bootset

# Create folder for current OS
mkdir -p /data/bootset/lk2nd/entries
mkdir -p /data/bootset/$2

# Copy device tree
cp /sys/firmware/fdt /data/bootset/$2/dtb.dtb

# Copy kernel
mkdir -p /sdcard/abm/temp/boot
unpackbootimg -i /sdcard/abm/stockboot.img -o /sdcard/abm/temp/boot > /dev/null 2>&1
cp /sdcard/abm/temp/boot/stockboot.img-zImage /dcard/bootset/$2/zImage

# Copy rd
cp /sdcard/abm/temp/boot/stockboot.img-ramdisk.gz /dcard/bootset/$2/inird.cpio.gz

# Create entery
cmdline=$(cat /proc/cmdline)
echo  "  default    Entry 01" >> /sdcard/bootset/lk2nd/lk2nd.conf
echo  "  timeout    5" >> /sdcard/bootset/lk2nd/lk2nd.conf
echo  "  title      "$3 >> /sdcard/bootset/lk2nd/entries/entry01.conf
echo  "  linux      "$2"/zImage" >> /sdcard/bootset/lk2nd/entries/entry01.conf 
echo  "  initrd     "$2"/initrd.cpio.gz" >> /sdcard/bootset/lk2nd/entries/entry01.conf
echo  "  dtb        "$2"/dtb.dtb" >> /sdcard/bootset/lk2nd/entries/entry01.conf
echo  "  options    " $cmdline  >> /sdcard/bootset/lk2nd/entries/entry01.conf
