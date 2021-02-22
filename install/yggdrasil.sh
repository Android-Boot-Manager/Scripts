#!/system/bin/sh

# Create working dir
mkdir -p /data/abm/bootset

# Backup
dd if=/dev/block/by-name/lk of=/data/abm/stocklk.img

# Flash bootloader to lk partition
dd if="$1" of=/dev/block/by-name/lk 

mkdir -p /cache/db /cache/lk2nd
mount --bind /cache /data/abm/bootset
mount --bind /data/abm/bootset/db /data/abm/bootset/lk2nd

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
  xtype      droid
  xsystem    real
  xdata      real
EOF

echo yggdrasil > /data/abm/codename.cfg
