#!/system/bin/sh

# Create working dir
mkdir -p /sdcard/abm

# Backup
dd if=/dev/block/by-name/lk of=/sdcard/abm/stocklk.img

# Flash lbootloader to lk partition
dd if="$1" of=/dev/block/by-name/lk 

# Kill logcat that opens some magisk log in cache
pkill -f logcat

# Format cache
umount -f /cache
./lz4 -d vollacache.img.lz4 vollacache.img
dd if=vollacache.img of=/dev/block/by-name/cache
rm vollacache.img

# Mount cache
mount -t ext4 /dev/block/by-name/cache /cache
mount --bind /cache /data/abm/bootset
mkdir -p /data/abm/bootset/db
mkdir -p /data/abm/bootset/lk2nd
mount --bind /data/abm/bootset/db /data/abm/bootset/lk2nd

# Create folder for entries
mkdir -p /data/abm/bootset/db/entries

# Create entry
cat << EOF >> /data/abm/bootset/db/db.conf
   default    Entry 01
   timeout    5
EOF
cat << EOF >> /data/abm/bootset/db/entries/entry01.conf
  title      $3
  linux      null
  initrd     null
  dtb        null
  options    null
  xRom       real
  xRomSystem real
  xRomData   real
EOF

cat yggdrasil > /data/abm/codename.cfg
