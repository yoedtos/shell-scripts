## autopower.sh
A bash shell script that allow your host computer to power on and off with fixed date/time

* #### Requirement
  Enable Power on By RTC in BIOS setup, make it wake up every day

  Make the script run on startup with cron

  `sudo crontab -e`

  add `@reboot /bin/bash /path/autopower.sh`  

* ##### Configuration example
  ```
  # Configuration
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
  ```

* ##### <span style="color:red">Note
This script was tested in centos 5 and 6 (kernel 2.6.18 and 2.6.32)
