cat > /data/abm-part.cfg << EOF
mkdir -p /data/bootset/lk2nd
mount -t ext4 /dev/block/by-name/cache /cache
mount --bind /cache /data/bootset
mount --bind /data/bootset/db /data/bootset/lk2nd
EOF

cat > /data/abm-part.2.cfg << EOF
# useless.
EOF
