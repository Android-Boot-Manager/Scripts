#!/system/bin/sh

# Create working dir
mkdir -p /sdcard/abm

# Backup
dd if=/dev/block/by-name/lk  of=/sdcard/abm/stocklk.img

# Flash lbootloader to lk partition
dd if="$1" of=/dev/block/by-name/lk 

#Kill logcat that opens some magisk log in cache
pkill -f logcat

# Format cache
umount -f /cache
true | mke2fs /dev/block/by-name/cache

# Mount cache
mkdir -p /data/bootset
mount -t ext4 /dev/block/by-name/cache /cache

# Create folder for entries
mkdir -p /cache/db/entries

# Create entry
cat << EOF >> /dcache/db/db.conf
   default    Entry 01
   timeout    5
EOF
cat << EOF >> /data/bootset/lk2nd/entries/entry01.conf
  title      $3
  linux      null
  initrd     null
  dtb        null
  options    null
EOF

