#!/bin/bash
#############################
### First Tier functions ####
#############################

function settings() {
		target="$USER@$ip:"
		ssh="ssh $USER@$ip"
		ftp_ssh="ssh -qt $USER@$ip"
		folder="/home/$USER/backups/"
		scp="scp -q "
		log_file="/var/log/$0/$0.log"
		status_file="/tmp/status.tmp"
		i=0
		n=0
		f=0
}

function dump_data() {
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
		#Set name standards in first so its same throughout whole script
		set_name_obj
		dump_data
	done
}

function failed_dump() {
	for dbname in ${failed[*]}; do
		status=1
		dump_data
	done
}


##############################################################
#### Second tier functions, called mainly from first tier ####
##############################################################

function check_log() {
	if [ ! -s $log_file ]; then
		touch $log_file
		log_entry="Log file was created" send_log
	fi
		log_entry="Script started" send_log
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
		date_log=`date '+%b %d %R:%S'`
}

function dump_database_obj() {
		#Creating folders if needed
		mkdir="mkdir -p ${dbfilepath}"
	if [ ! -d ${dbfilepath} ]; then
		$mkdir
    	$ssh "$mkdir"
    fi
    if [ ! -s $dbsend ]; then
		echo "temp" > $dbsend
		md5sum $dbsend > $dbsend_md5
	fi
}

function check_dump_obj() {
		#Removes completed dump from status file
		sed -i '/'$db'/d' $status_file
}

function send_dump_obj() {
		$scp$dbsend $target$dbsend
}

function check_send_obj() {
		$ssh "md5sum $dbsend > $dbsend_md5"
		$ssh "cat $dbsend_md5" | diff - "$dbsend_md5"
		#checks md5, and if its first or second time it runs
	if [ $? != 0 ]; then
			case $status in
				0)
					add_fail_md5_obj ;;
				1)
				log_entry="Md5 check failed twice on $db" send_log ;;
			esac
	else
		if [ $is_ftp == 1 ]; then
			set_ftp_settings
		fi			
		#If md5 checks out, remove previous local backup and look for old backups on remote
		remove_local_obj
		remove_old_obj
	fi

}
##############################################################
#### Third tier functions, called mainly from second tier ####
##############################################################

function add_fail_md5_obj() {
		#removes remote objects and add failed items to fail array
		log_entry="Md5 check failed on $db, removing remote and retrying" send_log
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

function remove_local_fail_obj() {
		#Remove remote objects
		rm $dbsend
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

#### Main script that calls functions ####
#### Ex running, ./script --type weekly --ip 10.10.10.10 --db "customer1_db customer2_db" --ftp "customer3_db" ####

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
	#Adds array to a status file
	printf "%s\n" ${dbs[*]} >> $status_file
    send_array="${dbs[*]}"
	is_ftp="0"
	run_backup
fi

#Checks if status file is empty
check_status_file
log_entry="Script ended \n --------------------------------------" send_log
