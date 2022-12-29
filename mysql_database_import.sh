#!/bin/bash
# Database mysqldump script
MYSQL_DATABASE=''
MYSQL_HOST_IP='localhost'
MYSQL_HOST_PORT='3306'
MYSQL_HOST_USER=''
MYSQL_HOST_PASS=''
TLOG=/tmp/dbimport.log
MYSQL_DB_IMPORT=/var/lib/mysql/db_import_temp

<<COMMENT4
# to take backup of existing database before import
BACKUP_DB_PATH=/home/mysql_db/schema/
CURRENT_DATE=`date +%Y-%m-%d_%H:%M:%S`
DB_SCHEMA_FILE="${BACKUP_DB_PATH}/${CURRENT_DATE}_${MYSQL_DATABASE}.schema.sql.gz"

echo "Taking present DB schema backup."

mysqldump --host=$MYSQL_HOST_IP --user=$MYSQL_HOST_USER --password=$MYSQL_HOST_PASS --no-data --port=$MYSQL_HOST_PORT -R --databases $MYSQL_DATABASE| gzip -c > ${DB_SCHEMA_FILE}

COMMENT4

# Linux bin paths, change this if it can not be auto detected via which command.
mysqldump="$(mysqldump)"
START=$(date +%s)
now="$(date)"
printf "Current date and time %s\n" "$now" >> $TLOG

echo "Step 0: Truncate present DB" >> $TLOG

mysql -Nse 'show tables' -D $MYSQL_DATABASE -u$MYSQL_HOST_USER -p$MYSQL_HOST_PASS | while read table; do echo "SET FOREIGN_KEY_CHECKS = 0;truncate table \`$table\`;SET FOREIGN_KEY_CHECKS = 1;"; done | mysql $MYSQL_DATABASE -u'$MYSQL_HOST_USER' -p$MYSQL_HOST_PASS

echo "Database mysql $MYSQL_DATABASE truncate is done." >> $TLOG

# copy DB files
echo "Step1: DB copy" >> $TLOG
# from remote server
echo "$now DB Copy from production is in progress " >> $TLOG
sshpass -p 'user_password' rsync -av username@hostname:/backup_location/$MYSQL_DATABASE/all-databases_$(date -d "1 days ago" '+%Y-%m-%d').sql.gz $MYSQL_DB_IMPORT/ 
# from mount point
rsync -av username@$MYSQL_DATABASE.polycom.com:/backup_location//$MYSQL_DATABASE/all-databases_$(date -d "1 days ago" '+%Y-%m-%d').sql.gz $MYSQL_DB_IMPORT/ 

echo "Step2: DB extract" >> $TLOG
cd $MYSQL_DB_IMPORT/ 
gzip -d *.gz

echo "Step3: removing DEFINER from sql files" >> $TLOG
# removing DEFINER from the *.sql files
echo "removing DEFINER from the *.sql files"  >> $TLOG
sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i *.sql

echo "Step3.1: replace character set and collation from sql files" >> $TLOG
sed -i 's/utf8/utf8mb4/g' *.sql

<<c_1
echo "Step4: replacing db name sql files"
# changing db name from the *.sql files
echo "changing db name from the *.sql files"
#sed -i '/$MYSQL_DATABASE/s/^confluence1\?/#/' *.sql
sed -i 's/$MYSQL_DATABASE/confluence1/g' *.sql
c_1

echo "Step5: Importing db schema" >> $TLOG

# log file and set permissions
#echo "$now Importing the schema"  >> $TLOG
#mysql -u'$MYSQL_HOST_USER' -p$MYSQL_HOST_PASS $MYSQL_DATABASE < /var/lib/mysql/db_import_temp/*.schema.sql
#echo "Deleting DB Schema file." >> $TLOG
#rm -rf *.schema.sql

echo "Step6: Importing db data" >> $TLOG
echo "$now Importing the database" >> $TLOG
mysql -u$MYSQL_HOST_USER -p$MYSQL_HOST_PASS --one-database $MYSQL_DATABASE < $MYSQL_DB_IMPORT/all-databases_$(date -d "1 days ago" '+%Y-%m-%d').sql

echo "Import is done" >> $TLOG
echo "Deleting DB Data file." >> $TLOG
rm -rf *.sql

echo "Step7: Sending notification" >> $TLOG
now="$(date)"
printf "Current date and time %s\n" "$now" >> $TLOG
echo "Import is done at $now," >> $TLOG
echo ""
echo ""
echo "Dear Team, 
Import of $MYSQL_DATABASE DB is done with above logs.
Thanks and regards
DBA Team" | mail -s "DB Import status" xyz@abc.com < $TLOG
true > $TLOG
