######## Prerequiste ######
Database: database_stats
Table: size
create database database_stats;
use database_stats;
CREATE TABLE database_stats.size (
        ID INT auto_increment primary key NOT NULL,
        DAY DATETIME NOT NULL,
        DATABASE_NAME varchar(100) NOT NULL,
        DATABASE_SIZE varchar(100) NOT NULL
)
ENGINE=InnoDB
DEFAULT CHARSET=latin1
COLLATE=latin1_swedish_ci;
==============================================
# Main Script
#!/bin/bash
# Monitor MySQL Database Size
## Mysql DB Credentials
dba_team=xyz@abc.com
DB_USER=''
DB_PASSWD=''
DB_NAME='confluence'
SDB_NAME='database_stats'
#time=$(date +"%Y-%m-%d %T")
time=$(date "+%Y%m%d%H%M%S")
DB_GROWTH_F='/tmp/DB_GROWTH.log'

echo "DB Size check for database: $DB_NAME on $HOSTNAME"
DB_SIZE=$(mysql -u$DB_USER -p$DB_PASSWD -e "SELECT  sum((data_length + index_length) / 1024 / 1024) as 'Size in MB'
FROM information_schema.TABLES
WHERE table_schema = '$DB_NAME';" -s -N)
echo "$DB_NAME  DB size is $DB_SIZE"

mysql -u$DB_USER -p$DB_PASSWD $SDB_NAME << EOF
INSERT INTO database_stats.size
(DAY, DATABASE_NAME, DATABASE_SIZE)
VALUES('$time', '$DB_NAME', '$DB_SIZE');
EOF


DB_GROWTH=$(mysql -u$DB_USER -p$DB_PASSWD $SDB_NAME -e "SELECT
  m1.ID,
  date_format(m1.DAY, '%Y-%m-%d %T') AS DAY,
  m1.DATABASE_SIZE,
  COALESCE(m1.DATABASE_SIZE - (SELECT m2.DATABASE_SIZE
                     FROM size m2
                     WHERE m2.ID = m1.ID - 1), 0) AS GROWTH_In_MB
FROM size m1;")

echo "----- Growth -----"
echo "$DB_GROWTH"
echo "$DB_GROWTH" > $DB_GROWTH_F
#echo "Check the growth and alert the user."
DB_G_V=$(tail -n 1 $DB_GROWTH_F | awk '{print $5}')
#echo " $DB_G_V "
rm -rf $DB_GROWTH_F
if [[ "$DB_G_V" > 0 ]]
then
       echo "Database growth by $DB_G_V."
           echo "Dear Team,

        Time: $(date)
        Server : $(hostname)
        Alert: Database growth by $DB_G_V.

Thanks and regards
SysAdmin Team

        " |
     mail -r no_reply@abc.com -s "Alert: Database growth by $DB_G_V " "$dba_team"
elif [[ "$DB_G_V" < 0 ]]
then
       echo "Database growth by $DB_G_V."
           echo "Dear Team,

        Time: $(date)
        Server : $(hostname)
        Alert: Database growth by $DB_G_V.

Thanks and regards
SysAdmin Team

        " |
     mail -r no_reply@abc.com -s "Alert: Database growth by $DB_G_V " "$dba_team"
else
       echo "No change in the database."
fi

echo "End of script."
