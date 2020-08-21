dialogchoice 'Installation' 'You are going to install ubuntu touch, using sytem image and halium boot. Are you sure?'
dialoginfo 'Installation' 'Please select halium boot file'
dialogfile halium-boot
dialoginfo 'Installation' 'Please select systemimage'
dialogfile systemimage
dialogtext 'Enter name in menu' ROM_name
dialogloading Demo 'Please wait, installing...'
exec 'ls /' output
dialogloadingquit
dialoginfo Demo 'exec gave %output%'
