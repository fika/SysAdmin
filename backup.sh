#!/bin/bash
#############################
### First Tier functions ####
#############################

function settings() {
		target="$USER@$ip:"
		ssh="ssh $USER@$ip"
		ftp_ssh="ssh -qt $USER@$ip"
		folder="/home/$USER/backups"
		scp="scp -q "
		file="$(basename $0)"
		log_file="/var/log/$file/$file.log"
		status_file="/tmp/status.tmp"
		i=0
		n=0
		f=0
}

function dump_data() {
		set_name_obj
		dump_database_obj
		check_dump_obj
		send_dump_obj
		check_send_obj
		log_entry="$db successfully backed up" send_log
}

function send_backup() {
	for dbname in $send_array; do
		#Status is used for if statement to see if its first or second time backup runs
		status=0
		dump_data
	done
}

function failed_dump() {
	for dbname in ${failed[*]}; do
		status=1
		dump_data
	done
}


###############################
#### Second tier functions ####
###############################

function check_log() {
	if [ ! -s $log_file ]; then
		touch $log_file
		log_entry="Log file was created" send_log
	fi
		backup_type_obj
		log_entry="Script started, $backup backup" send_log
}

function send_log() {
		set_date
		echo -e "$date_log | $log_entry" >> $log_file
}

function check_status_file() {
	#Looks if there is anything in the temporary status file
	if [ -s $status_file ]; then
		log_entry="Status file was not empty, the following dumps was not valid: $(cat $status_file)" send_log

	fi
		rm $status_file 2> /dev/null

}

function prev_script_run() {
		killvar=`ps -ef | grep $0 |grep -v $$ | grep -v grep | awk '{print $2}'`
	if [ ! -z "$killvar" ]; then
		kill -9 $killvar
		log_entry="Script was running, killed $killvar" send_log
	fi
}

function set_name_obj() {
		#Sets namestandards
		db="$dbname"
		chown_user="${db%_*}:${db%_*}"
	if [ $is_ftp -eq 1 ]; then
		dbfilepath=$folder/sftp/$db/$backup
	else
		dbfilepath=$folder/nonftp/$db/$backup
	fi
		set_date
		dbsend=$dbfilepath/$db.$date
		dbsend_md5=$dbsend.md5
}

function set_date() {
		date=`date '+%F'`
		date_log=`date '+%b %d %R:%S'`
}

function dump_database_obj() {
		#Creating folders if needed
		mkdir="mkdir -p ${dbfilepath}"
	if [ ! -d ${dbfilepath} ]; then
		$mkdir
    	$ssh "$mkdir"
    fi
    if [[ ! $(ls $dbfilepath | grep $dbsend) ]]; then
    	/usr/pgsql-9.3/bin/pg_dump --username vivo -o $db | gzip > $dbsend
		dump_ret=${PIPESTATUS[0]}
		return $dump_ret
	fi
}

function check_dump_obj() {
		#Removes completed dump from status file
	if [ $? -eq 0 ]; then
		md5sum $dbsend > $dbsend_md5
		sed -i '/'$db'/d' $status_file
	else
		case $status in
			0)
				remove_local_fail_obj
				log_entry="Dump check failed on $db, removing local and retrying" send_log
				add_fail_md5_obj ;;
			1)
				remove_local_fail_obj
				log_entry="Dump check failed twice on $db" send_log 
				continue ;;
		esac

	fi
}

function send_dump_obj() {
		$scp$dbsend $target$dbsend
		$ssh "md5sum $dbsend > $dbsend_md5"
}

function check_send_obj() {		
		$ssh "cat $dbsend_md5" | diff - "$dbsend_md5"
		#checks md5, and if its first or second time it runs
	if [ $? != 0 ]; then
			case $status in
				0)
					remove_remote_obj
					log_entry="Md5 check failed on $db, removing remote and retrying" send_log
					add_fail_md5_obj ;;
				1)
					remove_remote_obj
					log_entry="Md5 check failed twice on $db" send_log
					continue ;;
			esac
	else
		if [ $is_ftp -eq 1 ]; then
			set_ftp_settings
		fi			
		#If md5 checks out, remove previous local backup and look for old backups on remote
		remove_old_obj
	fi

}
##############################
#### Third tier functions ####
##############################

function add_fail_md5_obj() {
		#removes remote objects and add failed items to fail array
		failed[$i]=$db
		let i++
		continue
}

function set_ftp_settings() {
		#Chown and chmod remote ftp file
		$ftp_ssh "sudo chown $chown_user $dbsend* ; sudo chmod 400 $dbsend*"
}


function remove_local_fail_obj() {
		#Remove local failed dump
		rm $dbsend
}

function remove_remote_obj() {
		#Remove remote objects
		$ssh "rm $dbsend*"
}

function remove_old_obj() {
		#Add .done to files that are complete and transfered on local and removes previous backup
		find $dbfilepath -name "*.done" -exec rm {} \;
		mv "$dbsend" "$dbsend"".done"
		mv "$dbsend_md5" "$dbsend_md5"".done"
		backup_type_obj
		#Use find to remove old backups on remote server
		$ssh "find $dbfilepath -name "*.$(date -d "$rm_time $backup_type ago" "+%F")*" -exec rm {} \;"
}

function backup_type_obj() {
	#This will determine, how find will look for files
	if [[ $(date +%d) -eq 01 ]]; then 
		backup="monthly"
		backup_type="months"
		rm_time="18" 
	elif [[ $(date +%u) -eq 6 ]]; then 
		backup="weekly"
		backup_type="weeks"
		rm_time="8"
	else
		backup="daily" 
		backup_type="days"
		rm_time="14"
	fi
}

##########################################
#### Main script that calls functions ####
##########################################

while [ $# -ge 1 ];do
	case $1 in
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

#Check and rotate log file 
check_log
#Checks if there is a previous status file
check_status_file

#Checks if there is a process already running
prev_script_run

function run_backup() {
	send_backup
	failed_dump
	failed=
}

if [ ${#ftp[@]} -gt 0 ]; then
	#Adds array to a status file
	printf "%s\n" ${ftp[*]} >> $status_file
	send_array="${ftp[*]}"
	is_ftp="1"
	run_backup
fi

if [ ${#dbs[@]} -gt 0 ]; then
	printf "%s\n" ${dbs[*]} >> $status_file
	send_array="${dbs[*]}"
	is_ftp="0"
	run_backup
fi

#Checks if status file is empty
check_status_file
log_entry="Script ended \n --------------------------------------" send_log
