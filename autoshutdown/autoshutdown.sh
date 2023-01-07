#!/bin/bash
#
#  Shell Script to auto shutdown without 
#  ssh and samba activity
#  - re crontab entry to start on boot
#    @reboot /bin/bash autoshutdown
#
#  - to run on console 
#    $ nohup bash autoshutdown.sh &
#
#  autoshutdown.sh v1.2.0
#  by yoedtos   2020/05/11
#
#
#--------------------------------------------------------------------
#
# Configuration

TIMEOUT=30
PWOFF_DELAY=5 

#-----functions-------------------------------------------------------
#
# if there's ssh user activity return 1
check_users() {
    local term
    local ssh

    term=$(users | wc -w)
    ssh=$(netstat | grep ssh | grep ESTABLISHED | wc -l)

    if [ "$term" -gt 0  ]; then
       return 1
    elif [ "$ssh" -gt 0  ]; then
       return 1
    fi

}

check_ftp-rsync() {
    local ftp
    local rsync

    ftp=$(netstat | grep ftp | grep ESTABLISHED | wc -l)
    rsync=$(netstat | grep rsync | grep ESTABLISHED | wc -l)

    if [ "$ftp" -gt 0  ] || [ "$rsync" -gt 0  ]; then
       return 1
    fi

}

# if there's no samba user activity return 10
check_samba() {

FILES_LOCKED=$(/usr/bin/smbstatus | grep "Locked files:" )
if [ -z "$FILES_LOCKED" ]; then
    return 10
fi

}

shutdown() {

   local message

   message=("AutoShutdown is running. Will Shutdown in $PWOFF_DELAY minutes")
   echo $message
   /sbin/shutdown -h +$1 $message

}

suspend() {

   /bin/systemctl suspend -i

}

#--------------------------main code--------------------------------------------

COUNTER=0

while :
do
        check_users
        if [ $? -eq 0 ]; then
                if [ $TIMEOUT == $COUNTER ]; then
                      shutdown $PWOFF_DELAY
                      break;
                else
                   check_samba
                   if [ $? -eq 10 ]; then
                      check_ftp-rsync
                      if [ $? -eq 0 ]; then
                         COUNTER=$((COUNTER +1))
                         sleep 1m
                         #echo $COUNTER
                      else
                         #echo "Transfer Activity: Sleeping 5 minutes"
                         COUNTER=0
                         sleep 5m
                      fi
                   else
                      #echo "Samba Activity: Sleeping 5 minutes"
                      COUNTER=0
                      sleep 5m
                   fi
                fi
        else
          #echo "User Online: Sleeping 10 minutes"  
          sleep 10m
        fi
done

