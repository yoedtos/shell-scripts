## rsync-folder.sh
A bash shell script that use rsync to synchronize folders with a samba server

* #### Requirement
samba-client  
cifs-utils

* ##### Configuration example
```
#------ configuration ----------------
# folders to sync
DIRECTORIES="myfolder projects"
# samba user
USER=share_user
# samba password
PASS=share_pass
# samba share name
REMOTE=share/folder
# servers list
# host name
NAME1="NAS Server"
# host ip address
SERVER1=192.168.1.100
...
```

* ##### <span style="color:red">Note
Before use this script is recommended to make a backup of your files
