#!/bin/bash
NC='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
PINK='\033[1;35m'
BLUE='\033[1;36m'

queriesDir="/home/_server_data/sql/queries/"

get_mssql_conn() {
	DBId=`grep -m1 -w "DBId" /home/data_${1}/cabal/AuthDBAgent.ini | cut -d "=" -f 2`
	DBPwd=`grep -m1 -w "DBPwd" /home/data_${1}/cabal/AuthDBAgent.ini | cut -d "=" -f 2`
	mssqlConn="/opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U $DBId -P $DBPwd"
}

get_db_list() {
	case $1 in
		db)
			local tmpFile=`docker exec sql_${2} mktemp`
			docker cp ${queriesDir}db_list.sql sql_${2}:${tmpFile}
			dbs=`docker exec sql_${2} ${mssqlConn} -i ${tmpFile} -h -1 | tr " " "\n"`
			docker exec sql_${2} /bin/bash -c "rm -f ${tmpFile}"
			;;
		
		file)
			if [[ ! -f /home/data_${2}/cabal_structure/db_list ]]; then
				bklist=`ls /home/data_${2}/mssql/backup/*.bak`
				for bkfile in $bklist
				do
					db=`basename $bkfile | cut -f 1 -d '.'`
					echo $db >> /home/data_${2}/cabal_structure/db_list
				done
			fi
			if [[ -f /home/data_${2}/cabal_structure/db_list ]]; then
				dbs=`cat /home/data_${2}/cabal_structure/db_list`
			else
				dbs=''
			fi
			;;
	esac
	cat << EOF > /home/data_${2}/cabal_structure/db_list
$dbs
EOF
	sed -i '/^$/d' /home/data_${2}/cabal_structure/db_list
}

check_container_exists() {
	local cont=`docker ps --filter name=${1} --format "{{.Names}}" -a | grep -w "cabal_${1}"`
	if [[ $cont = '' ]]; then
		if [[ ! $2 == "-dt" ]] ; then
			echo -e "${RED}An argument must be added to the command.${NC}"
			echo -e "${YELLOW}Supported arguments:${NC}"
			docker ps --filter name=cabal_ --format "{{.Names}}" -a | sed 's/cabal_//'
			echo
		fi
		return 1
	fi
}

check_container_running() {
	local cont=`docker ps --filter status=running --format "table {{.Names}}" | grep -w ${1}_${2} || echo 1`
	if [[ $cont -eq 1 ]]; then
		if [[ $3 != "-dt" ]] ; then
			echo -e "${RED}${1}_${2} container is not running.${NC}"
			echo -e "${YELLOW}Use this commands to start it:${NC}"
			echo -e "${PINK}docker start sql_${2}${NC}"
			echo -e "${PINK}docker start cabal_${2}\n${NC}"
		fi
		return 1
	fi
}

check_gms() {
	local port=`grep -m1 -w "Port" /home/data_${1}/cabal/GlobalMgrSvr.ini | cut -d "=" -f 2`
	local ping=`docker exec cabal_$1 nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
	if [[ $ping -eq 1 ]]; then
		return 1
	fi
}

char_count() {
	echo -n "$1" | wc -c | awk '{print $1}'
}

screate_check_cont_name() {
	local cont=`docker ps --filter name=${1} --format "{{.Names}}" -a | grep -w "cabal_${1}"`
	if [[ ! $cont = '' ]]; then
		echo -e "\n${BLUE}The server id '${1}' is already in use.${NC}"
		echo -e "${BLUE}Aborted.\n${NC}"
		return 1
	fi
}

screate_check_mssql_port() {
	# local cont=`docker ps --filter publish=${1} --format "{{.Ports}}" -a | awk '{n=split($NF,arr1,"->"); split(arr1[n],arr2,"/"); print arr2[1]}'`
	# if [[ ! $cont = '' ]]; then
	# 	local cont=`docker ps --filter publish=${1} --format "{{.Names}}" -a`
	# 	echo -e "\n${BLUE}MSSQL port $1 already in use by another container (${cont}).${NC}"
	# 	echo -e "${BLUE}Aborted.\n${NC}"
	# 	return 1
	# fi
	
	local cont=`docker ps -q -a`
	for contid in $cont
	do
		local findstr=".[0].HostConfig.PortBindings.\"1433/tcp\""
		local port=`docker inspect $contid | jq $findstr | jq '.[0].HostPort' | sed 's/\"//g'`
		if [[ $port -eq $1 ]]; then
			local contName=`docker inspect $contid | jq '.[0].Name' | sed 's/\"//g' | cut -f2 -d/`
			echo -e "\n${BLUE}MSSQL port $1 already in use by another container (${contName}).${NC}"
			echo -e "${BLUE}Aborted.\n${NC}"
			return 1
		fi
	done
	
	local ping=`nmap $2 -p $1 | grep -q "/tcp *open " || echo 1`
	if [[ $ping -ne 1 ]]; then
		echo -e "\n${BLUE}MSSQL port $1 already in use by another service.${NC}"
		echo -e "${BLUE}Aborted.\n${NC}"
		return 1
	fi
}

screate_check_cabal_port() {
	local cport=$1
	local cont=`docker ps -q -a`
	
	while true
	do
		local ctrlport=$cport
		for contid in $cont
		do
			local findstr=".[0].HostConfig.PortBindings.\"${cport}/tcp\""
			local port=`docker inspect $contid | jq $findstr`
			if [[ $port != 'null' ]]; then
				local cport=$(($cport+100))
			fi
		done
		
		if [[ $ctrlport -eq $cport ]]; then
			break
		fi
	done
	cabal_port=$cport
	port_range="${cabal_port}-$(($cabal_port+99))"
}

screate_check_mssql_password() {
	mssql_user_chk=`echo $1 | tr [:upper:] [:lower:]`
	mssql_pass_chk=`echo $2 | tr [:upper:] [:lower:]`
	complexity=0
	if [[ "$2" == *[A-Z]* ]]; then
		complexity=$(( $complexity + 1 ))
	fi
	if [[ "$2" == *[a-z]* ]]; then
		complexity=$(( $complexity + 1 ))
	fi
	if [[ "$2" == *[0-9]* ]]; then
		complexity=$(( $complexity + 1 ))
	fi
	if [[ "$2" == *'!'* || "$2" == *'$'* || "$2" == *'#'* || "$2" == *'%'* ]]; then
		complexity=$(( $complexity + 1 ))
	fi
	if [[ ${#2} -lt 8 || $mssql_pass_chk == *$mssql_user_chk* || $mssql_pass_chk == 'sa' || $complexity -lt 3 ]]; then
		echo -e "\n${BLUE}MS SQL server password does not meet security requirements.${NC}"
		echo -e "${BLUE}Details:${NC}"
		echo -e "https://learn.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-ver15"
		echo -e "${BLUE}Aborted.\n${NC}"
		return 1
	fi
}

screate_check_backup() {
	local check_backup=`tar -ztf $1 | grep _server_data.tar.gz`
	if [[ $check_backup == '' ]]; then
		echo -e "\n${BLUE}No suitable backup available.${NC}"
		echo -e "${BLUE}Aborted.\n${NC}"
		return 1
	fi
}

progress_bar() {
	case $1 in
		start)
			pbi=''
			echo -ne "  [                    ]\r"
			;;
		work)
			pbi="$pbi#"
			echo -ne "  [$pbi\r"
			if [[ `char_count $pbi` -eq 20 ]]; then
				echo -ne "  [                    ]\r"
				pbi=''	
			fi
			sleep 0.1
			;;
		stop)
			echo -ne "                        \r"
			;;
	esac
}

countdown()
(
	IFS=:
	set -- $*
	secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
	tput sc
	while [ $secs -gt 0 ]
	do
		sleep 1 & echo -e -n "\033[1;33m"
		printf "\rWaiting for starting $daemon:			[ %02d:%02d:%02d ]" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
		echo -e -n "\033[0m"
		secs=$(( $secs - 1 ))
		wait
	done
	tput rc;tput el
)

getValueFromINI() {
	local sourceData=$1; local paramName=$2;
	## 1. Get value "platform=%OUR_VALUE%"
	## 2. Remove illegal characters
	echo $(echo "$sourceData" | sed -n '/^'$paramName'=\(.*\)$/s//\1/p' | tr -d "\r" | tr -d "\n");
}

formatted_date() {
	date +"%Y-%m-%d_%H-%M"
}

cabal_service() {
	spaces="                                   "
	case $1 in
		start)
			echo_string="Starting $3"
			echo_string="${echo_string:0:35}${spaces:0:$((35 - ${#echo_string}))}"
			if [[ ! $4 == '-dt' ]]; then
				echo -n "${echo_string}"
			fi
			output=`docker exec cabal_$2 supervisorctl start $3`
			case "$output" in
			  *started*)
				srv_status="[${GREEN}OK${NC}]"
				;;
			  *ERROR*)
				srv_status="[${RED}FAILED${NC}]"
				;;
			esac
			if [[ ! $4 == '-dt' ]]; then
				echo -e "$srv_status"
			fi
			;;
		stop)
			echo_string="Stopping $3"
			echo_string="${echo_string:0:35}${spaces:0:$((35 - ${#echo_string}))}"
			if [[ ! $4 == '-dt' ]]; then
				echo -n "$echo_string"
			fi
			output=`docker exec cabal_$2 supervisorctl stop $3`
			case "$output" in
			  *stopped*)
				srv_status="[${GREEN}OK${NC}]"
				;;
			  *ERROR*)
				srv_status="[${RED}FAILED${NC}]"
				;;
			esac
			if [[ ! $4 == '-dt' ]]; then
				echo -e "$srv_status"
			fi
			;;
		restart)
			echo_string="Restarting $3"
			echo_string="${echo_string:0:35}${spaces:0:$((35 - ${#echo_string}))}"
			if [[ ! $4 == '-dt' ]]; then
				echo -n "$echo_string"
			fi
			output=`docker exec cabal_$2 supervisorctl restart $3`
			case "$output" in
			  *stopped*)
				srv_status="[${GREEN}OK${NC}]"
				;;
			  *ERROR*)
				srv_status="[${RED}FAILED${NC}]"
				;;
			esac
			if [[ ! $4 == '-dt' ]]; then
				echo -e "$srv_status"
			fi
			;;
		reload)
			echo_string="Reloading $3"
			echo_string="${echo_string:0:35}${spaces:0:$((35 - ${#echo_string}))}"
			if [[ ! $4 == '-dt' ]]; then
				echo -n "$echo_string"
			fi
			output=`docker exec cabal_$2 /bin/bash -c "/usr/bin/pkill -HUP -f /usr/bin/$3"`
			srv_status="[${GREEN}OK${NC}]"
			if [[ ! $4 == '-dt' ]]; then
				echo -e "$srv_status"
			fi
			;;
		startProxy)
			echo_string="Starting Proxy service #$3"
			echo_string="${echo_string:0:35}${spaces:0:$((35 - ${#echo_string}))}"
			if [[ ! $4 == '-dt' ]]; then
				echo -n "${echo_string}"
			fi
			output=`docker exec cabal_$2 supervisorctl start gms_proxy:gms_proxy_"$3"`
			case "$output" in
			  *started*)
				srv_status="[${GREEN}OK${NC}]"
				;;
			  *ERROR*)
				srv_status="[${RED}FAILED${NC}]"
				;;
			esac
			if [[ ! $4 == '-dt' ]]; then
				echo -e "$srv_status"
			fi
			;;
	esac
}

cabal_create_backup() {
	local type=$1
	local srv_id=$2
	local dt=$3
	
	local LOCALDIR="/home/_server_backups/$type"
	local TMPDIR=`mktemp -d`
	
	case $type in
		daily)
			local curr_date=`date "+%u_%A_%H"`
			;;
		hourly)
			local curr_date=`date "+%H"`
			;;
		*)
			local curr_date=`date "+%Y.%m.%d_%H-%M-%S"`
			;;
	esac

	if ! [ -d $LOCALDIR ]; then
		mkdir -p $LOCALDIR
	fi

	# Full backup
	if [[ $srv_id == "-f" || $srv_id == "--full" ]] ; then
		local servers=`docker ps --filter name=cabal_ --format "{{.Names}}" -a | sed 's/cabal_//'`
		for srv in $servers
		do
			check_container_running sql $srv $dt
			if [[ $? -ne 1 && ! $type == 'removed_servers' ]]; then
				/usr/bin/backup_dbs $srv -s $dt
				sleep 10
			fi
			cd /home/data_$srv
			tar --exclude="logs" -czf $TMPDIR/cabal_${srv}_backup.tar.gz *
			sync; echo 1 > /proc/sys/vm/drop_caches
		done
		local backupname=cabal_full_backup_${curr_date}.tar.gz
	
	# Server backup
	else
		check_container_exists $srv_id
		if [[ $? -eq 1 ]]; then
			/bin/bash -c "rm -rf $TMPDIR"
			exit 0
		fi
		check_container_running sql $srv_id $dt
		if [[ $? -ne 1 && ! $type == 'removed_servers' ]]; then
			/usr/bin/backup_dbs $srv_id -s $dt
			sleep 10
		fi
		cd /home/data_$srv_id
		tar --exclude="logs" -czf $TMPDIR/cabal_${srv_id}_backup.tar.gz *
		local backupname=cabal_${srv_id}_backup_${curr_date}.tar.gz
	fi

	cd /home/_server_data
	tar -czf $TMPDIR/_server_data.tar.gz *

	cd $TMPDIR
	tar -czf $LOCALDIR/$backupname *
	/bin/bash -c "rm -rf $TMPDIR"
	
	if [[ ! $dt == "-dt" ]]; then
		echo -e "\n${GREEN}The backup is saved as $LOCALDIR/$backupname\n${NC}"
	fi

	# Отправка по ftp
	. /home/_server_data/ftp.conf
	
	if [[ $USE_FTP -eq 1 ]] ; then
		if [[ ! $dt == "-dt" ]]; then
			echo -e "\n${YELLOW}Sending via ftp...\n${NC}"
		fi
		cd $LOCALDIR
		ftp -n $FTPHOST <<EOF > /dev/null
quote USER $FTPUSER
quote PASS $FTPPASS
binary
mkdir _server_backups
mkdir _server_backups/${type}
cd _server_backups/${type}
put ${backupname}
prompt
quit
EOF
		if [[ ! $dt == "-dt" ]]; then
			echo "Done"
		fi
		# /bin/bash -c "rm -f $LOCALDIR/$backupname"
	fi
	
	cd

	# Чистим кэш ОЗУ
	sync; echo 1 > /proc/sys/vm/drop_caches
}

cabal_restore_backup() {
	local backup_file=$1
	local srv_prefix=$2
	local TMPDIR=`mktemp -d`
	local TARGETDIR=/home/data_$srv_prefix
	mkdir -p $TARGETDIR
	
	tar -C $TMPDIR -zxf $backup_file
	/bin/bash -c "mv -f $TMPDIR/cabal $TARGETDIR/"
	/bin/bash -c "mv -f $TMPDIR/cabal_bin $TARGETDIR/"
	/bin/bash -c "mv -f $TMPDIR/cabal_structure $TARGETDIR/"
	/bin/bash -c "mv -f $TMPDIR/cabal_war $TARGETDIR/"
	mkdir -p $TARGETDIR/cabal_scripts
	mkdir -p $TARGETDIR/logs
	mkdir -p $TARGETDIR/mssql
	mkdir -p $TARGETDIR/cabal_scripts/gms_proxy
	mkdir -p $TARGETDIR/cabal_scripts/services_checker
	/bin/bash -c "mv -f $TMPDIR/cabal_scripts/cabal_services $TARGETDIR/cabal_scripts/"
	/bin/bash -c "mv -f $TMPDIR/cabal_scripts/odbc $TARGETDIR/cabal_scripts/"
	/bin/bash -c "mv -f $TMPDIR/cabal_scripts/autorun.sh $TARGETDIR/cabal_scripts/"
	/bin/bash -c "mv -f $TMPDIR/mssql/backup $TARGETDIR/mssql/"
	/bin/bash -c "cp -af /home/_server_data/sh/container_scripts/init.sh $TARGETDIR/cabal_scripts/"
	/bin/bash -c "cp -af /home/_server_data/sh/container_scripts/proxy.py $TARGETDIR/cabal_scripts/gms_proxy/"
	/bin/bash -c "cp -af /home/_server_data/sh/container_scripts/services_checker.sh $TARGETDIR/cabal_scripts/"
	/bin/bash -c "cp -af /home/_server_data/sh/container_scripts/status.sh $TARGETDIR/cabal_scripts/"
	if [[ -f $TMPDIR/cabal_scripts/crontab ]]; then
		/bin/bash -c "mv -f $TMPDIR/cabal_scripts/crontab $TARGETDIR/cabal_structure/crontab"
	else
		if [[ -f $TMPDIR/cabal_scripts/cron ]]; then
			/bin/bash -c "mv -f $TMPDIR/cabal_scripts/cron $TARGETDIR/cabal_structure/crontab"
		fi
	fi
	if [[ -f $TMPDIR/cabal_structure/crontab ]]; then
		/bin/bash -c "mv -f $TMPDIR/cabal_structure/crontab $TARGETDIR/cabal_structure/crontab"
	else
		if [[ -f $TMPDIR/cabal_structure/cron ]]; then
			/bin/bash -c "mv -f $TMPDIR/cabal_structure/cron $TARGETDIR/cabal_structure/crontab"
		fi
	fi
	if [[ -f $TMPDIR/cabal_structure/backup_conf ]]; then
		/bin/bash -c "mv -f $TMPDIR/cabal_structure/backup_conf $TARGETDIR/cabal_structure/backup_conf"
	else
		echo "autobackup=0" > $TARGETDIR/cabal_structure/backup_conf
	fi
	/bin/bash -c "rm -rf $TMPDIR"
}

get_server_num() {
	snum=0
	if [[ ! $1 == '-dt' && $1 -gt 0 ]] ; then
		snum=$1
		if [[ $snum -lt 10 ]]; then
			snum="0$snum"
		fi
	fi
}
