#!/bin/bash
#
# 
#  Script syncronize directories and file with
#  rsync using samba shares (cifs)
#
#  v1.1.0
# 
#  by yoedtos  2023/05/14
#
#
#-------------------------------------
ROOT_TMP=mnt/sync_tmp
MARKFILE=$ROOT_TMP/.hasUpdate
SCRIPTDIR=$(dirname $BASH_SOURCE) 
SCRIPT=$0
. ${SCRIPT%.sh}.conf
RSYNC=$(command -v rsync)
HOST=$(hostname -s)
RED='\033[0;31m'
NC='\033[0m' 
PARAM="-rltDh"

check_dep() {
 if ! [ -x $RSYNC ]; then
    echo -e "${RED} Dependency failed: rsync could not be found!${NC}"
    exit
 fi
}

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
  if [ $NUMBER == "0" ]; then
     exit 1
  elif [ $NUMBER == "1" ]; then
     	SERVER=$SERVER1
  elif [ $NUMBER == "2" ]; then
     	SERVER=$SERVER2
  elif [ $NUMBER == "3" ]; then
     	SERVER=$SERVER3
  fi
  clear
}

check_root() {
  if [ $(id -u) -ne 0 ]; then
      echo -e "${RED} This command need root!${NC}"
      exit
  fi
}

set_numeric_id() {
  U_UID=$(stat -c '%u' $0)
  U_GID=$(stat -c '%g' $0) 
}

set_owner() {
  chown -R $U_UID:$U_GID $1
}

mount_share() {
  mkdir -p $ROOT_TMP	
  mount.cifs //$SERVER/$REMOTE/ $ROOT_TMP -o vers=1.0,user=$USER,password=$PASS,uid=$U_UID,gid=$U_GID,credentials=$SIGNIN
  
  if [[ $? != 0 ]]; then
      rmdir -p $ROOT_TMP
      echo -e "${RED}Terminated due to error!${NC}"
      exit
  fi
  cd $SCRIPTDIR
}

umount_share() {
  umount $ROOT_TMP 
  rmdir -p $ROOT_TMP
}

update_mark() {
  touch $MARKFILE
  echo $HOST > $MARKFILE
}

get_mark() {
  if [ -f $MARKFILE ]; then
    read -r MARKSIG < $MARKFILE
  fi 
}

has_update() {
  get_mark
  UPDATE=false
  if [[ -n $MARKSIG ]]; then
     if [[ $HOST != $MARKSIG ]]; then
        UPDATE=true
	return
     fi
  fi 
}

check_mark() {
  get_mark
  if [[ ! -n $MARKSIG ]]; then
    exit 1
  fi
}

synchronize() {
  LOCAL=$1
  echo "Working on $LOCAL"
  echo "Synchronizing..."
  if [ $UPDATE == true ]; then
     mkdir ${LOCAL}_remote
     echo -e "${RED} Has modification on remote!${NC}"
     echo "Pulling from Remote"
     echo "Moving to: ${LOCAL}_remote"
     rsync $PARAM $ROOT_TMP/$LOCAL/ ${LOCAL}_remote
  fi
  echo "Pushing from Local"
  rsync $PARAM --delete $LOCAL $ROOT_TMP
  echo
}

restore() {
  LOCAL=$1
  echo "Working on $LOCAL"
  echo "Restoring..."
  rsync $PARAM --delete $ROOT_TMP/$LOCAL/ $LOCAL  
  echo
}

error() {
  echo -e "${RED} Invalid command call!${NC}"
  help
  exit
}

help() {
  echo " To backup use:"
  echo -e "\t\$ bash $0 -b"
  echo " To restore use:"
  echo -e "\t\$ bash $0 -r"
}

end_msg() {
  if [ $UPDATE == true ]; then
     echo -e "${RED}\t-------------------------------------"
     echo -e "\tDue to files update in remote."
     echo -e "\tManual merge file is required!"
     echo -e "\t-------------------------------------${NC}"
  fi
  echo "Script ended!"
}

show_alert() {
  echo -e "${RED}\t-------------------------------------"
  echo -e "\tThis action will delete files !!!"
  echo -e "\t-------------------------------------${NC}"
  read -p $'\tIt is Ok?: (Y/N)' CONFIRM
  if [ $CONFIRM == "N" ]; then
     exit 1
  fi
}

show_status() {
  printf 'Server %s\t | Job\n' | expand -t 14
  echo -e $SERVER "|" $JOB "\n"
}

#------------ main code -----------------------
	check_dep
	check_root
	if [ "$1" == "-r" ]; then
	   check_mark
	   show_alert
	   JOB=restore
	elif [ "$1" == "-b" ]; then  
           JOB=synchronize
	else
	   error	
	fi
	choose_host
	show_status
	set_numeric_id
	mount_share
	cd $SCRIPTDIR
	has_update
	for directory in $DIRECTORIES
	  do
	    $JOB $directory
	    set_owner $directory
	  done
	update_mark
	umount_share
	end_msg

