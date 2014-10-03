#!/bin/bash

### First Tier functions
function send_backup() {
	for dbname in $send_array; do
		#Status is used for if statement to see if its first or second time backup runs
		status=0
		#Sets namestandards
		set_name_obj
		#dump database
		dump_database_obj
		#check the dump
		check_dump_obj
		#Sending database
		send_backup_obj
		#Check if send was complete
		echo "This is send_backup func" "Ftp is set to $is_ftp"
		check_send_obj
		echo $db "was run from send_backup"
	done
}

function failed_backup() {
	for dbname in ${failed[*]}; do
		#Status is used for if statement to see if its first or second time backup runs
		status=1
		#Sets namestandards
		set_name_obj
		#dump database
		dump_database_obj
		#check the dump
		check_dump_obj
		#Sending database
		send_backup_obj
		#Check if send was complete
		echo "This is failed_backup func" "Ftp is set to $is_ftp"
		check_send_obj
		echo $db "was run from failed"
	done
}

#### Second tier functions, called mainly from first tier ####

function settings() {
		#User is current user who runs script, and remote serveruser
		target="$USER@$ip:"
		ssh="ssh $USER@$ip"
		ftp_ssh="ssh -qt $USER@$ip"
		folder="/home/$USER/backups/"
		scp="scp -q "
		status_file="/tmp/status.tmp"
		i=0
		n=0
		f=0
}

function backup_type_obj() {
	#This will determine, how find will look for files
	case $backup in
        	d | daily )
                backup_type="days"
                rm_time="14" ;;
        	w | weekly )
                backup_type="weeks"
                rm_time="8" ;;
        	m | montly )
                backup_type="months"
                rm_time="18" ;;
        	y | yearly )
                backup_type="years"
                rm_time="10" ;;
        	z | zero ) #This is for temporary file-remove
                backup_type="days"
                rm_time="0" ;;
	esac
}

function check_status_file() {
		#Checks if there is a previous status file
	if [ ! -s $status_file ]; then
		echo "Status file was empty, no backups remain in loop"
		
	else
		echo "Status file was not empty, report to nagios"

	fi
		rm $status_file 2> /dev/null

}

function prev_script_run() {
		#kills previous script and reports to nagios
		killvar=`ps -ef | grep $0 |grep -v $$ | grep -v grep | awk '{print $2}'`
	if [ -z "$killvar" ]; then
		echo "No previous script running"
	else
		kill -9 $killvar
		echo "Killed previous process report to nagios"
	fi
}

function set_name_obj() {
		#Sets namestandards
		db="$dbname"
		chown_user="${db%_*}:${db%_*}"
	if [ $is_ftp == 1 ]; then
		dbfilepath=$folder/sftp/$db/$backup
	else
		dbfilepath=$folder/nonftp/$db/$backup
	fi
		set_date
		dbsend=$dbfilepath/$db.$date
		dbsend_md5=$dbsend.md5
}

function set_date() {
		date=`date '+%F_%T'`
		#date_log=`date '+%b %d %R:%S'`
}

function dump_database_obj() {
		#Creating folders if needed
		mkdir="mkdir -p ${dbfilepath}"
	if [ ! -d ${dbfilepath} ]; then
		$mkdir
    	$ssh "$mkdir"
    fi
    	#dumping database and creating md5sum
		touch $dbsend
		md5sum $dbsend > $dbsend_md5
}

function check_dump_obj() {
	#Still to come, check if dump is valid. Similar to the check_send if statement
	#Removes completed dump from status file
		sed -i '/'$db'/d' $status_file
}

function send_backup_obj() {
		#send backups
		$scp$dbsend $target$dbsend
}

function check_send_obj() {
		#ssh and compares md5 files
		$ssh "md5sum $dbsend > $dbsend_md5"
		$ssh "cat $dbsend_md5" | diff - "$dbsend_md5"
		#checks md5, and if its first or second time it runs
	if [ $? != 0 ]; then
			case $status in
				0)
					add_fail_obj ;;
				1)
				echo "Backup failed two times, report to nagios" ;;
			esac
	else
		#If the target is ftp, mod file with ftp settings
		if [ $is_ftp == 1 ]; then
			set_ftp_settings
		fi			
		#When all is complete, remove previous local backup and mark this one as done
		remove_local_obj
		#When all is complete, remove old enough objects on remote
		remove_old_obj
	fi

}

#### Third tier functions, called mainly from second tier ####

function add_fail_obj() {
		#removes remote objects and add failed items to fail array
		remove_remote_obj
		failed[$i]=$db
		let i++
		continue
}


function set_ftp_settings() {
		#Chown and chmod remote ftp file
		$ftp_ssh "sudo chown $chown_user $dbsend* ; sudo chmod 400 $dbsend*"
}


function remove_local_obj() {
		#Add .done to files that are complete and transfered on local and removes previous backup
		find $dbfilepath -name "*.done" -exec rm {} \;
		mv "$dbsend" "$dbsend"".done"
		mv "$dbsend_md5" "$dbsend_md5"".done"
}

function remove_remote_obj() {
		#Remove remote objects
		$ssh "rm $dbsend*"
}

function remove_old_obj() {
		backup_type_obj
		#Use find to remove old backups on remote server
		$ssh "find $dbfilepath -name "*.$(date -d "$rm_time $backup_type ago" "+%F")*" -exec rm {} \;"
}

#### Main script that calls functions ####
#### Ex running, ./script --type weekly --ip 10.10.10.10 --db "customer1_db customer2_db" --ftp "customer3_db"

while [ $# -ge 1 ];do
	case $1 in
	-t | --type) #New, daily, weekly, montly                                                                                                                                                                        
		backup="$2" ;;
	-i | --ip) #The remote IP                                                                                                                                                       
		ip="$2" ;;
	-d | --db) #Databases to backup                                                                                                                                                                        
		dbs[$n]="$2"
		let n++ ;;
	-f | --ftp) #Databases to backup to ftp                                                                                                                                                      
		ftp[$f]="$2"
		let f++;;
	*)
		check_usage $1 ;;
    esac
    shift 2
done

#Importing settings
settings

#Checks if there is a previous status file
check_status_file

#Checks if there is a process already running
prev_script_run

if [ ${#ftp[@]} -gt 0 ]; then
	#Adds array to a status file
	printf "%s\n" ${ftp[*]} >> $status_file
    send_array="${ftp[*]}"
	is_ftp="1"
	send_backup
	failed_backup
	#This will empty the fail array
	failed=
fi

if [ ${#dbs[@]} -gt 0 ]; then
	#Adds array to a status file
	printf "%s\n" ${dbs[*]} >> $status_file
    send_array="${dbs[*]}"
	is_ftp="0"
	send_backup
	failed_backup
	#This will empty the fail array
	failed=
fi

#Checks if status file is empty, temp echos
check_status_file
