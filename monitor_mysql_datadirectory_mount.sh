#!/bin/bash
dba_team=abc@abc.com

data_dir=$(cat /etc/my.cnf | grep 'datadir' | cut -d'=' -f2-)
echo "$data_dir"
data_dir_mount_u=$(df -h $data_dir | awk '{ print $5 }' | cut -d'%' -f1 | tail -n +2)
echo "$data_dir_mount_u"

#### Notification users in case the utilization is above 85%. Kindly defined the threshold value. ################
if [ $data_dir_mount_u -ge 85 ]; then
    echo "Dear Team,
	
	Time: $(date)
	Server : $(hostname)
	Utilization %: $data_dir_mount_u
	Alert: Running out of space.
	
Thanks and regards
SysAdmin Team
	
	" |
     mail -r no_reply@abc.com -s "Alert: Almost out of disk space $data_dir_mount_u " "$dba_team"
else 
   echo "MySQL Mount Utilization is under 85%."
  fi

echo "End of script."
