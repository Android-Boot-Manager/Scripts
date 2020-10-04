native getString installing_title installing_title
native getString install_sailfish install_sailfish
native getString select_sfos_zip select_sfos_zip
native getString enter_rom_name enter_rom_name
native getString installing_msg installing_msg
dialogchoice %installing_title% %install_sailfish%
dialoginfo %installing_title% %select_sfos_zip%
dialogfile sfoszip
dialogtext %enter_rom_name% ROM_name
dialogloading Demo %installing_msg%
global 'cd /data/data/org.androidbootmanager.app/assets/Toolkit/ && /data/data/org.androidbootmanager.app/assets/Scripts/add_os/yggdrasil/add_sailfish.sh "%ROM_name%" %sfoszip% >/sdcard/abm/rom.log 2>&1' output
dialogloadingquit
