dialogchoice 'Installation' 'You are going to install ubuntu touch, using sytem image and halium boot. Are you sure?'
dialoginfo 'Installation' 'Please select halium boot file'
dialogfile halium-boot
dialoginfo 'Installation' 'Please select systemimage'
dialogfile systemimage
dialogtext 'Enter name in menu' ROM_name
dialogloading Demo 'Please wait, installing...'
global 'cd /data/data/org.androidbootmanager.app/assets/Toolkit/ && /data/data/org.androidbootmanager.app/assets/Scripts/add_os/yggdrasil/add_ubuntutouch_sytemimage_haliumboot.sh hi %systemimage% %halium-boot% %ROM_name% >/sdcard/abm/rom.log 2>&1' output
dialogloadingquit
