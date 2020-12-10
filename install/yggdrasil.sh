#!/system/bin/sh

# Create working dir
mkdir -p /sdcard/abm /data/abm/bootset

# Backup
dd if=/dev/block/by-name/lk of=/sdcard/abm/stocklk.img

# Flash lbootloader to lk partition
dd if="$1" of=/dev/block/by-name/lk 

# Kill logcat that opens some magisk log in cache
pkill -f logcat
pkill logcat

# Format cache
umount /cache
./lz4 -d vollacache.img.lz4 vollacache.img
dd if=vollacache.img of=/dev/block/by-name/cache
rm vollacache.img

# Mount cache
mount -t ext4 /dev/block/by-name/cache /cache
sleep 1
mkdir -p /cache/db /cache/lk2nd


# Create folder for entries
mkdir -p /data/abm/bootset/db/entries

# Create entry
cat << EOF >> /data/abm/bootset/db/db.conf
   default    Entry 01
   timeout    5
EOF
cat << EOF >> "/data/abm/bootset/db/entries/$2.conf"
  title      $3
  linux      null
  initrd     null
  dtb        null
  options    null
  xRom       real
  xRomSystem real
  xRomData   real
EOF

echo yggdrasil > /data/abm/codename.cfg
