## autoshutdown.sh
A bash shell script that allow your host computer, auto power off when there's not activity 

* #### Requirement

  Make the script run on startup with cron

  `sudo crontab -e`

  add `@reboot /bin/bash /path/autoshutdown.sh`  

* ##### Configuration example
  ```
  # Configuration
  # This make power off after 30 minutes of inactivity
  TIMEOUT=30
  # Delay for 5 minutes
  PWOFF_DELAY=5

  ```

* ##### <span style="color:red">Note
This script was tested in centos 5 and 6 (kernel 2.6.18 and 2.6.32)
