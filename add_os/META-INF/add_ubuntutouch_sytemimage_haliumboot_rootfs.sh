native getString str_installing_title installing_title
dialoginfo %str_installing_title% 'No, not really. This is just an ABM MetaScript demo.'
dialogchoice Demo Continue?
dialogloading Demo 'Please wait...'
exec 'sh -c "sleep 3; echo magic"' output
dialogloadingquit
dialoginfo Demo 'exec gave %output%'
dialogfile file
dialoginfo Demo 'You selected %file%'
dialoginfo Demo Bye
