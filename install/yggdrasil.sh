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
./lz4 -d vollacache.img.lz4 vollacache.img
dd if=vollacache.img of=/dev/block/by-name/cache
rm vollacache.img

# Mount cache
mkdir -p /data/bootset/lk2nd
mount -t ext4 /dev/block/by-name/cache /cache
mount --bind /cache /data/bootset
mkdir -p /data/bootset/db
mount --bind /data/bootset/db /data/bootset/lk2nd

# Create folder for entries
mkdir -p /cache/db/entries

# Create entry
cat << EOF >> /cache/db/db.conf
   default    Entry 01
   timeout    5
EOF
cat << EOF >> /cache/db/entries/entry01.conf
  title      $3
  linux      null
  initrd     null
  dtb        null
  options    null
  xRom       real
  xRomSystem /dev/block/by-name/system
  xRomData   /dev/block/by-name/data
EOF

cat > /data/abm-part.cfg << EOF
mkdir -p /data/bootset/lk2nd
mount -t ext4 /dev/block/by-name/cache /cache
mount --bind /cache /data/bootset
mount --bind /data/bootset/db /data/bootset/lk2nd
EOF

cat > /data/abm-part.2.cfg << EOF
# useless.
EOF
