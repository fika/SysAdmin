#!/bin/bash

function set_date() {
		date=`date '+%F_%T'`
		#date_log=`date '+%b %d %R:%S'`
}

function add_fail_obj() {
		#removes remote objects and add failed items to fail array
		remove_remote_obj
		failed[$i]=$dbname
		let i++
		continue
}

function check_send_obj() {
		#ssh and compares md5 files
		$ssh "md5sum $dbsend > $dbsend.md5"
		$ssh "cat $dbsend.md5" | diff - "$dbsend.md5"
		#checks md5, and if its first or second time it runs
	if [ $? != 0 ] && [ $status == 0 ]; then
			add_fail_obj
	elif [ $? != 0 ] && [ $status == 1 ]; then
			echo "Backup failed two times, report to nagios"
	else
			#if md5 checks out, remove local file and check if there is a backup old enough to remove
			remove_local_obj
			remove_old_obj
	fi
}

function send_backup_obj() {
		#send backups
		$scp$dbsend $target$dbsend
}

function remove_local_obj() {
		#Remove local objects that is older then 1 day
		find $dbfilepath -name "*.$(date -d "1 days ago" "+%F")*" -exec rm {} \;
}

function remove_remote_obj() {
		#Remove remote objects
		$ssh "rm $dbsend*"
}

function remove_old_obj() {
		#Use find to remove old backups on remote server
		$ssh "find $dbfilepath -name "*.$(date -d "$days $backup_type ago" "+%F")*" -exec rm {} \;"
}

function dump_database_obj() {
		#Creating folders if needed
		dbfilepath=$folder$dbname
		mkdir="mkdir -p ${dbfilepath}"
	if [ ! -d ${dbfilepath} ]; then
		$mkdir
    		$ssh "$mkdir"
    	fi
    	#dumping database and creating md5sum
		set_date
		dbsend=$dbfilepath/$dbname.$date
		touch $dbsend
		md5sum $dbsend > $dbsend.md5
}

function check_dump() {
	#Still to come, check if dump is valid. Similar to the check_send if statement
	#Removes completed dump from status file
		sed -i '/'$dbname'/d' $status_file
}

function send_backup() {
	for dbname in ${dbs[*]}; do
		#Status is used for if statement to see if its first or second time backup runs
		status=0
		#dump database
		dump_database_obj
		#check the dump
		check_dump
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	done
}

function failed_backup() {
	for dbname in ${failed[*]}; do
		#Status is used for if statement to see if its first or second time backup runs
		status=1
		#dump database
		dump_database_obj
		#check the dump
		check_dump
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	done
}

while [ $# -ge 1 ];do
	case $1 in
	-t | --type) #What type of backup, days, weeks, months, years                                                                                                                                                                        
		backup_type="$2"
		;;
	-f | --find) #How old together with type, like 18 for: days 18                                                                                                                                                                      
		days="$2"
		;;
	-i | --ip) #The remote IP                                                                                                                                                       
		ip="$2"
		;;
	-d | --db) #Databases to backup                                                                                                                                                                        
		dbs[$n]="$2"
		let n++
		;;
	*)
		check_usage $1
		;;
    esac
    shift 2
done

#Checks if there is a process already running
ps -ef | grep $0 | if grep -v $$
then
echo "There is another process running, will kill it"
fi

#Adds array to a status file
status_file="/tmp/status.tmp"
printf "%s\n" ${dbs[*]} > $status_file

#Ex ./script.sh --type days --find 18 --ip 192.168.122.53 --db "db1 db2 db3 db4"

target="vivo@$ip:"
ssh="ssh vivo@$ip"
folder="/home/vivo/backups/"
scp="scp -q "

i=0
n=0

send_backup
failed_backup

#Checks if status file is empty, temp echos
if [ ! -s $status_file ]; then
	echo "Status file was empty, no backups remain in loop"
	rm $status_file
else
	echo "Status file was not empty, report to nagios"
	cat $status_file
	rm $status_file
fi
