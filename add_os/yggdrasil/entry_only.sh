#!/system/bin/sh

# Script for installing other OSes. Parameters: ROM folder name, ROM name in menu

TK="/data/data/org.androidbootmanager.app/assets/Toolkit"
PATH="$TK:$PATH"
cd "$TK" || exit 24

# Create folder for new OS
mkdir -p "/data/abm/bootset/$1"

# Create entry
cat << EOF >> "/data/abm/bootset/db/entries/$1.conf"
  title      $2
  linux      $1/null
  initrd     $1/null
  dtb        $1/null
  options    bootopt=64S3,32N2,64N2
EOF

echo "Installation done."