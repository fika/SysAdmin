#!/bin/bash

dbs=(
database_one
database_two
database_three
database_four
database_five
database_six
)

target="viktor@192.168.122.53:"
ssh="ssh viktor@192.168.122.53"
folder="/home/viktor/backups/"
scp="scp -q "

i=0

function set_date() {
	date=`/bin/date '+%Y%m%d%H%M%S'`
	date_log=`/bin/date '+%b %d %R:%S'`
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

function dump_database_obj() {
		#dumping database and creating md5sum
		set_date
		dbsend=$folder$dbname.$date
		touch $dbsend
		md5sum $dbsend > $dbsend.md5	
}

function send_backup() {
	for dbname in "${dbs[@]}"; do
		#dump database
		dump_database_obj
		#before send, check if dump is valid
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	if [ $? != 0 ]; then
		#add to fail que & remove remote objects
		add_fail_obj
	else
		#if md5 checks out, remove local file
		remove_local_obj
		fi
	done
}

function failed_backup() {
	for dbname in ${failed[*]}; do
		#dump database
		dump_database_obj
		#before send, check if dump is valid
		#Sending database
		send_backup_obj
		#Check if send was complete
		check_send_obj
	if [ $? != 0 ]; then
		#remove remote and logg second failed attempt
		remove_remote_obj
		echo "fail"
	else
		#if md5 checks out, remove local file
		remove_local_obj
		
		fi
	done
}

send_backup
failed_backup
