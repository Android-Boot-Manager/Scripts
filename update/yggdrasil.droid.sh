#!/system/bin/sh

# Flash lk bootloader to lk partition
dd if=/data/data/org.androidbootmanager.app/files/lk2nd.img of=/dev/block/by-name/lk 

echo "===== INFORMATION ======"
echo "This feature often does not"
echo "work for unknown reasons"
echo "on this device. This is not"
echo "harmful, just nothing will"
echo "happen. You can flash the"
echo "update via fastboot flash lk"
