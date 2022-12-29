#!/bin/bash
dba_team=xyz@abc.com
fromdate=$(date | awk '{print $1 " "$2 " " $3}')
cd /data_dump_location/ || return
a=$(grep -w "FAILED\|Failed\|Error\|REJECTED" data_dump.log | grep "$fromdate")
echo "$a"
if [[ -n "${a// /}" ]];
then
b=$(echo $a)
echo "Dear Team,

Errors/Warnings found in $HOSTNAME MySQL Server Dump Log, kindly check the log file.
---------------------------------------------------------------
"$b"

---------------------------------------------------------------
Thanks and regards
DBA Team
" | mail -r no_reply@abc.com -s "Errors/Warnings $HOSTNAME MySQL Server Dump Log" "$dba_team"

else
echo "No Errors/Warnings found in MySQL Server Dump Log"     
fi

echo "End of script."
