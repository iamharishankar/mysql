#!/bin/bash
# monitor server log every hour to avoid repeated alerts.
dba_team=xyz@abc.com
fromdate=$(date +"%Y-%m-%d")
cd /var/log/ || return
a=$(grep -w "FAILED\|Failed\|Error\|REJECTED" mysqld.log | grep "$fromdate")
if [[ -n "${a// /}" ]];
then
b=$(echo $a)
echo "Dear Team,

Errors/Warnings found in MySQL Server Log, kindly check the log file.
---------------------------------------------------------------
"$b"

---------------------------------------------------------------
Thanks and regards
DBA Team
" | mail -r no_reply@abc.com -s "Errors/Warnings found in MySQL Server Log" "$dba_team"

else
echo "No Errors/Warnings found in MySQL Server Log"     
fi

echo "End of script."
