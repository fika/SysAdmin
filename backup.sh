#!/bin/bash
#Ex, call script ./script.sh --ip 192.168.122.53 --db "customer_db customer2_db" from crontab every day
#############################
### First Tier functions ####
#############################

function settings() {
		target="$USER@$ip"
		ssh="ssh $USER@$ip"
		ftp_ssh="ssh -qtt $USER@$ip"
		folder="/home/$USER/backups"
		scp="scp -q"
		status_file="/tmp/status.tmp"
		i=0
		n=0
		f=0
}

function dump_data() {
		set_name_obj
	if [ -z $old_date ]; then
		dump_database_obj
		check_dump_obj
	fi
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
		backup_type_obj
		file="$(basename $0).$backup.log"
		log_file="/var/log/$(basename $0)/$file"
	if [ ! -s $log_file ]; then
		touch $log_file
		log_entry="Log file was created" send_log
	fi
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
	if [ -z $old_date ]; then
		date=`date '+%F'`
	else
		date="$old_date"
	fi
		date_log=`date '+%a %b %d %R:%S'`
}

function dump_database_obj() {
		#Creating folders if needed
	if [ ! -d ${dbfilepath} ]; then
		mkdir -p ${dbfilepath}
    	$ssh "mkdir -p ${dbfilepath}"
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
		$scp $dbsend $target:$dbsend
		if [ $? != 0 ]; then
			log_entry="$db.$date, no such file" send_log
			continue
		fi
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
		$ftp_ssh "sudo chown $chown_user $dbsend* ; sudo chmod 400 $dbsend*" 2> /dev/null
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
	if [ -z $old_date ]; then
		backup_type_obj
		#Use find to remove old backups on remote server
		remove_arr=$($ssh "ls $dbfilepath | grep -v ".md5" | awk -F'[(.)]' '{print \$2}'")
		for x in ${remove_arr[*]}; do
		        old=$(($(echo $(date --date="$(date '+%F')" +%s)) - $(echo $(date --date="$x" +%s))))
		                if [ "$old" -ge "$rm_time" ]; then
		                	$ssh "rm $dbfilepath/$db.$x*"
		                	log_entry="Removed $db.$x" send_log
		                fi
		done
	fi
}

function backup_type_obj() {
	#This will determine the backup type.
	if [[ "$(date +'%-m')" -eq "1" ]] && [[ "$(date +'%-d')" -eq "1" ]]; then
		backup="yearly"
		rm_time="10"
	elif [[ "$(date +'%-d')" -eq "1" ]]; then 
		backup="monthly"
		rm_time="47350800" 
	elif [[ "$(date +%u)" -eq "6" ]]; then 
		backup="weekly"
		rm_time="4842000"
	else
		backup="daily" 
		rm_time="1213200"
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
	-o | --old)
    	old_date="$2";;
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
	if [ -z $old_date ]; then
		printf "%s\n" ${ftp[*]} >> $status_file
	fi
	send_array="${ftp[*]}"
	is_ftp="1"
	run_backup
fi

if [ ${#dbs[@]} -gt 0 ]; then
	if [ -z $old_date ]; then
		printf "%s\n" ${dbs[*]} >> $status_file
	fi
	send_array="${dbs[*]}"
	is_ftp="0"
	run_backup
fi

#Checks if status file is empty
check_status_file
log_entry="Script ended \n --------------------------------------" send_log
