native getString installing_title installing_title
native getString install_ut_halium_boot_systemimage install_ut_halium_boot_systemimage
native getString select_halium_boot select_halium_boot
native getString select_system_image select_system_image
native getString enter_rom_name enter_rom_name
native getString installing_msg installing_msg
dialogchoice %installing_title% %install_ut_halium_boot_systemimage%
dialoginfo %installing_title% %select_halium_boot%
dialogfile halium-boot
dialoginfo %installing_title% %select_system_image%
dialogfile systemimage
dialogtext %enter_rom_name% ROM_name
dialogloading Demo %installing_msg%
global 'cd /data/data/org.androidbootmanager.app/assets/Toolkit/ && /data/data/org.androidbootmanager.app/assets/Scripts/add_os/yggdrasil/add_ubuntutouch_sytemimage_haliumboot.sh hi %systemimage% %halium-boot% "%ROM_name%" >/sdcard/abm/rom.log 2>&1' output
dialogloadingquit
