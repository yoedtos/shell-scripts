#!/bin/bash
#
#
#  Script syncronize directories and file with
#  rsync using samba shares (cifs)
#
#  v1.0.2
#
#  by yoedtos  2021/09/11
#
#
#
#
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
NAME2=""
SERVER2=
NAME3=""
SERVER3=
#-------------------------------------

ROOT_TMP=mnt/sync_tmp
SCRIPTDIR=$(dirname "$BASH_SOURCE")

choose_host() {
  echo
  echo -e "\tPlease Select Host"
  echo -e "\t1) $NAME1"
  if [ "$NAME2" != "" ]; then
       echo -e "\t2) $NAME2"
  fi
  if [ "$NAME3" != "" ]; then
       echo -e "\t3) $NAME3"
  fi
  echo
  echo -e "\t0) Cancel"
  echo
  read -p $'\tEnter Number: ' NUMBER
  if [ "$NUMBER" == "0" ]; then
     exit 1
  elif [ "$NUMBER" == "1" ]; then
     	$SERVER1
  elif [ "$NUMBER" == "2" ]; then
     	$SERVER2
  elif [ "$NUMBER" == "3" ]; then
     	$SERVER3
  fi
}

check_root() {
  if [ $(id -u) -ne 0 ]; then
    echo "This command need root"
    exit
  fi
}

set_numeric_id() {
  U_UID=$(stat -c '%u' $0)
  U_GID=$(stat -c '%g' $0)
}

mount_share() {
  mkdir -p $ROOT_TMP
  mount.cifs //$SERVER/$REMOTE/ $ROOT_TMP -o vers=1.0,user=$USER,password=$PASS,uid=$U_UID,gid=$U_GID

  if [[ $? != 0 ]]; then
        rmdir -p $ROOT_TMP
        echo "Terminated due to error"
        exit
  fi
  cd $SCRIPTDIR
}

umount_share() {
  umount $ROOT_TMP
  rmdir -p $ROOT_TMP
}

update_mark() {
  touch $ROOT_TMP/.hasUpdate
  echo $HOSTNAME > $ROOT_TMP/.hasUpdate
}

get_mark() {
  read -r MARKSIG < $ROOT_TMP/.hasUpdate
}

synchronize() {
  LOCAL=$1
  echo "Working on $LOCAL"
  get_mark
  if [[ "$HOSTNAME" != "$MARKSIG" ]]; then
     echo "Update from Remote"
     rsync -auvh $ROOT_TMP/$LOCAL/ $LOCAL
  fi
  echo "Update from Local"
  rsync -auvh $LOCAL $ROOT_TMP
  echo "Synchronizing ..."
  rsync -auvh --delete $LOCAL $ROOT_TMP
  update_mark
  echo
}

restore() {
  LOCAL=$1
  echo "Working on $LOCAL"
  echo "Restoring ..."
  rsync -avh --delete $ROOT_TMP/$LOCAL/ $LOCAL
  echo
}

#------------ main code -----------------------

#	check_root
	if [ "$1" = "-r" ]; then
	  JOB=restore
	else
    JOB=synchronize
	fi
	choose_host
	echo $SERVER $JOB
	set_numeric_id
	mount_share
	for directory in $DIRECTORIES
	  do
	    $JOB $directory
	  done
	umount_share
