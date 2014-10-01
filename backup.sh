#!/bin/bash

target="vivo@192.168.122.53:"
ssh="ssh vivo@192.168.122.53"
folder="/home/vivo/backups/"
scp="scp -q "

i=0
n=0

function set_date() {
		date=`/bin/date '+%F_%T'`
		#date_log=`/bin/date '+%b %d %R:%S'`
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
}

function send_backup_obj() {
		#send backups
		$scp$dbsend $target$dbsend
}

function remove_local_obj() {
		#Remove local objects
		rm $dbsend*
}

function remove_remote_obj() {
		#Remove remote objects
		$ssh "rm $dbsend*"
}

function remove_old_obj() {
		$ssh "find $folder -name "*.$(date -d "$days $backup_type ago" "+%F")*" -exec rm {} \;"
}

function dump_database_obj() {
		#dumping database and creating md5sum
		set_date
		dbsend=$folder$dbname.$date
		touch $dbsend
		md5sum $dbsend > $dbsend.md5	
}

function send_backup() {
	#for dbname in "${dbs[@]}"; do (old for loop, keep for backup)
	for dbname in ${dbs[*]}; do
		#dump database
		dump_database_obj
		#before send, check if dump is valid (still to come)
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	if [ $? != 0 ]; then
		#add to fail que & remove remove objects
		add_fail_obj
	else
		#if md5 checks out, remove local file and check if there is a backup old enough to remove
		remove_local_obj
		remove_old_obj
		fi
	done
}

function failed_backup() {
	for dbname in ${failed[*]}; do
		#dump database
		dump_database_obj
		#before send, check if dump is valid (still to come)
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	if [ $? != 0 ]; then
		#logg second failed attempt
		echo "fail"
	else
		#if md5 checks out, remove local file and check if there is a backup old enough to remove
		remove_local_obj
		remove_old_obj
		fi
	done
}

while getopts d:t:b: GET; do
    case "$GET" in
      b)
		#What backup are you running, days, weeks, months, or years (Ex -b days)
		backup_type="$2" ;;
      t)
		#How old can remote backups be, number (Ex -t 18)
        days="$4" ;;
      d)
		#Adds everything in -d " " to the array. (Ex -d "db1 db2 db3")
		dbs[$n]="$6"
        let n++
        continue  ;;
    esac
done

send_backup
failed_backup
