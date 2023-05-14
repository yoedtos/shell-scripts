## rsync-folder.sh
A bash shell script that use rsync to synchronize folders with a samba server

* #### Requirement
samba-client  
cifs-utils

##### Configuration example
* Create credential file that contains a username and password. Change it to 600 permission

```bash
# touch /root/.share.cred
# chmod 600 /root/.share.cred
# nano /root/.share.cred
```

ex:
```
#----- credential ----------------
username=myuser
password=mypassword

```

* Edit the rsync-myfolders.conf

```
#----- configuration -------------
# folders to sync
DIRECTORIES="myfolder projects"
# samba share name
REMOTE=share/folder
## user credential
SIGNIN="/root/share.cred"
# servers list
# host name
NAME1="NAS Server"
# host ip address
SERVER1=192.168.1.100
...
```

* ##### <span style="color:red">Note
Before use this script is recommended to make a backup of your files
