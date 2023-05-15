#!/bin/bash
#
#  Shell Script to wake up machine from rtc alarm and shutdown
#  - require crontab entry to start on boot
#    @reboot /bin/bash autopower
#
#  - to run on console
#    $ nohup bash autopower.sh &
#
#  autopower.sh v1.7.1
#  by yoedtos   2023/05/15
#
#
#-------------------------------------------------------------------------------
# Configuration
#
# Weeday of Power ON/OFF
WEEKDAYON="Friday"
WEEKDAYOFF="Monday"
# Time of Power ON/OFF
TIMEON="23:00"
TIMEOFF="07:00"
# PowerOff Delay in minutes
PWOFF_DELAY="10"
# Run command before shutdown
BEFORE_PWOFF=
#-------------------------------------------------------------------------------
export PATH=$PATH:/usr/local/bin


# day of week (1..7); 1 is Monday
get_weekday() {

    local value

    value=$(date +"%u")

    return $value
}

get_date() {

    DATE=$(date +"%Y-%m-%d")
}

weekdays=( Monday Tuesday Wednesday Thursday Friday Saturday Sunday )

# return '1' if parameter is equal, '0' if is not
check_weekday() {

    local i=0;
    local value=0;
    local x

    for weekday in ${weekdays[@]}; do
        ((i++))
        if [ "${weekday}" = "$1" ]; then
            x="$i"
            break
        fi
    done

    get_weekday
    if [ "$x" -eq "$?" ]; then
        echo "Yes, today is ${weekdays[x-1]}"
	check_time_diff $TIMEOFF
	#echo $TIMEDIFF
	if [ $TIMEDIFF -lt $PWOFF_DELAY ]; then
	   echo "Will sleep 1 Day ..."
	   sleep 1d
           get_weekday
           echo "I'm up now --> ${weekdays[$?-1]}"
	fi
    fi

    return $value

}

# return diff in minutes
check_time_diff() {

	local today

  today=$(date '+%Y-%m-%d %H:%M')
	#echo "$DATE $today"
	TIMESEC_A=$(date -d "$DATE $1" +%s)
	TIMESEC_B=$(date -d "$today" +%s)
        #echo "$TIMESEC_A - $TIMESEC_B"
	TIMEDIFF=$((($TIMESEC_A-$TIMESEC_B)/60))
}


process_weekday() {

    local weekday
    local date
    local count=0;

    #date=$(date -d "2017-09-24 -2 days" +"%Y-%m-%d")
    date=$(date +"%Y-%m-%d")
    while [ $count -lt 7 ]
    do
      weekday=$(date -d "$date +$count days" +"%A")
      if [ $weekday == $1 ]
        then
            DATE=$(date -d "$date +$count days" +"%Y-%m-%d")
            break
        fi
      count=`expr $count + 1`
    done

}

process_shutdown() {

	check_time_diff $1
	RESULT=$(($TIMEDIFF-$PWOFF_DELAY))
	echo "Will sleep $RESULT minutes"
	sleep "$(($RESULT))m"

}

set_wakeup() {

        local wakeuptime

        wakeuptime=("$DATE $TIMEON:00")
        echo "Setting RTC WakeUp --> $wakeuptime"
        RTCTIME=("$wakeuptime")
        set_rtc
}

reset_wakeup() {

        local reset

        reset=$(date -d "120 days" +"%Y-%m-%d")
        echo "Resetting RTC Wakeup to $reset"
        RTCTIME=("$reset $TIMEON")
        set_rtc
}

set_rtc() {

        check_kernel
        result=$?

        if [ $result -eq 22 ]; then
           # if use utc format uncomment
           #seconds=$(date -u --date "$RTCTIME" +%s)
           seconds=$(date --date "$RTCTIME" +%s)
           echo "Seconds -- > $seconds"
           echo 0 > /sys/class/rtc/rtc0/wakealarm
           echo $seconds > /sys/class/rtc/rtc0/wakealarm
        elif [ $result -eq 21 ]; then
           echo $RTCTIME  > /proc/acpi/alarm
        fi

}

shutdown() {
	local message

	eval $BEFORE_PWOFF
	message=("AutoPower is running. Please save your work and logout")
        /sbin/shutdown -h +$1 $message

}

send_output() {
    local str1="nohup output [$0]"
    local output

    output=$(<nohup.out)
    rm nohup.out
    echo "$output" | mail -s "$str1" "root"

}

check_kernel() {

# Kernel versions 2.6.22 and newer
# use /sys/class/rtc/rtc0/wakealarm

# Kernel versions 2.6.21 and older
#  use /proc/acpi/alarm

        x="$(echo $(uname -r) | cut -b 5,6)"
        if [ $x -ge 22 ]; then
            echo "version 2.6.22 = or >"
            return 22
        elif [ $x -le 21 ]; then
            echo "version 2.6.21 = or <"
            return 21
        fi

}

#--------------------------------------------------------

		reset_wakeup
		check_weekday $WEEKDAYOFF
		if [ "$?" -eq 0 ]; then
			process_weekday $WEEKDAYOFF
			process_shutdown $TIMEOFF
			echo "I'm up now --> $(date '+%Y-%m-%d %H:%M')"
			process_weekday $WEEKDAYON
			set_wakeup
			shutdown $PWOFF_DELAY
			#send_output
		fi

#---------------------------------------------------------
