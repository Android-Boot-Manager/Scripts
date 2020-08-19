cat > /data/abm-part.cfg << EOF
mkdir -p /data/bootset
mount -t ext4 /dev/block/bootdevice/by-name/oem /data/bootset
EOF

cat > /data/abm-part.2.cfg << EOF
umount /data/bootset
EOF
