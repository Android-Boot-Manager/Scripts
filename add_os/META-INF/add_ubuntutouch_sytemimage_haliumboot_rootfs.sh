native getString str_installing_msg installing_msg
native getString str_installing_text installing_text
dialoginfo %str_installing_msg% 'No, not really. This is just an ABM MetaScript demo.'
dialogchoice Demo Continue?
dialogloading Demo 'Please wait...'
exec 'sleep 3; echo magic' output
dialoginfo Demo 'exec gave %output%'
dialogfile file
dialoginfo Demo 'You selected %file%'
dialoginfo Demo Bye
