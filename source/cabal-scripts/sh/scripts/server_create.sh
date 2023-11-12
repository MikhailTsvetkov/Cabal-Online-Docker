#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

. /home/_server_data/new_server.conf
cabal_container='mikhailtsvetkov/hardcore-cabal-server:3.1.0'
#cabal_container='hardcore-cabal-server:latest'
cabal_port=35001






echo -e "\n${RED}==> ${YELLOW}Checking the configuration...${NC}"


# Get server IP
host_addr=`hostname -I | awk '{print $1;}'`


# Check MSSQL version
if [[ $mssql_version -ne 2019 && $mssql_version -ne 2022 ]]; then
	echo -e "\n${BLUE}Unsupported MSSQL version $mssql_version.${NC}"
	echo -e "${BLUE}Set 2019 or 2022.${NC}"
	echo -e "${BLUE}Aborted.\n${NC}"
	exit 0
fi



# Check server id
screate_check_cont_name $srv_prefix
if [[ $? -eq 1 ]]; then
	exit 0
fi


# Check mssql port
screate_check_mssql_port $mssql_port $host_addr
if [[ $? -eq 1 ]]; then
	exit 0
fi


# Check mssql password
screate_check_mssql_password $mssql_user $mssql_pass
if [[ $? -eq 1 ]]; then
	exit 0
fi


# Check backup
screate_check_backup $backup_file
if [[ $? -eq 1 ]]; then
	exit 0
fi


# Get cabal port range
screate_check_cabal_port $cabal_port
# i=0
# while [[ $i -eq 0 ]]
# do
# 	chkPort=`docker ps --filter publish=${cabal_port} --format "{{.Ports}}" -a | awk '{n=split($NF,arr1,"->"); split(arr1[n],arr2,"/"); print arr2[1]}'`
# 	if [[ $chkPort = '' ]]; then
# 		i=1
# 	else
# 		cabal_port=$(($cabal_port+100))
# 	fi
# done
# port_range="${cabal_port}-$(($cabal_port+99))"


# Set autostart mode
if [[ $autostart -eq 1 ]]; then
	restart='always'
else
	restart='on-failure'
fi






echo -e "${RED}==> ${YELLOW}Unpacking files to a temporary directory... ${NC}"


curr_date=`date "+%Y%m%d_%H%M%S"`
TMPDIR="/tmp/rest_bkp_${curr_date}"
bkp_cnt=`tar -ztf $backup_file | grep -c _backup.tar.gz`
server_bkp=`tar -ztf $backup_file | grep _backup.tar.gz`
mkdir $TMPDIR
tar -C $TMPDIR -zxf $backup_file


# Get backup file
if [[ $bkp_cnt -ne 1 ]]; then
	echo -e "${BLUE}Several backups found. ${NC}"
	echo -e "${BLUE}The following backups are available for recovery: ${NC}"
	tar -ztf $backup_file | grep _backup.tar.gz
	while [[ -z $pref ]]
	do
		echo -e -n "\n${PINK}Enter the prefix of the backup you want to restore: ${NC}"
		read pref
	done
	chk_bkp=''
	while [[ $chk_bkp = '' ]]
	do
		chk_bkp=`tar -ztf $backup_file | grep cabal_${pref}_backup.tar.gz`
		if [[ $chk_bkp = '' ]]; then
			pref=''
			echo -e "${BLUE}The backup with the $pref prefix was not found. ${NC}"
			while [[ -z $pref || $pref = '' ]]
			do
				echo -e -n "\n${PINK}Enter the prefix of the backup you want to restore: ${NC}"
				read pref
			done
		fi
		backup_file=$TMPDIR/$chk_bkp
	done
else
	backup_file=$TMPDIR/$server_bkp
fi


# Unpacking the archive
if [ -d /home/data_${srv_prefix} ]; then
	echo -e "${BLUE}The directory /home/data_${srv_prefix} already exists. ${NC}"
	while [[ -z $ready_repl_b ]]
	do
		echo -e -n "\n${PINK}Replace? [Y]/[N]: ${NC}"
		read ready_repl_b
	done
	if [[ $ready_repl_b = 'Y' || $ready_repl_b = 'y' ]]; then
		echo -e "${RED}==> ${YELLOW}Move old dir to /home/___removed_data_${srv_prefix}_${curr_date} ${NC}"
		/bin/bash -c "mv -f /home/data_${srv_prefix} /home/___removed_data_${srv_prefix}_${curr_date}"

		echo -e "${RED}==> ${YELLOW}Restore ${srv_prefix} backup... ${NC}"
		cabal_restore_backup $backup_file $srv_prefix
	fi
else
	echo -e "${RED}==> ${YELLOW}Restore ${srv_prefix} backup... ${NC}"
	cabal_restore_backup $backup_file $srv_prefix
fi


# Set permissions
find /home/data_${srv_prefix}/cabal_scripts -type f -print0 | xargs -0 -r -n 100 -P 6 chmod 0700
find /home/data_${srv_prefix}/cabal_scripts/gms_proxy -type f -print0 | xargs -0 -r -n 100 -P 6 chmod 0700

if [ -d $TMPDIR ]; then
	/bin/bash -c "rm -rf $TMPDIR"
fi

if ! [ -d /home/data_${srv_prefix}/logs ]; then
	mkdir -p /home/data_${srv_prefix}/logs
fi






echo -e "${RED}==> ${YELLOW}Run sql_${srv_prefix}...${NC}"

docker run --name sql_$srv_prefix \
-e "ACCEPT_EULA=Y" \
-e "MSSQL_PID=Express" \
-e "MSSQL_SA_PASSWORD=$mssql_pass" \
--restart=$restart \
-p $mssql_port:1433 \
-v /home/data_${srv_prefix}/mssql/backup:/var/opt/mssql/backup \
-v /var/opt/mssql/data_${srv_prefix}:/var/opt/mssql/data \
-d mssql-tz-$mssql_version 1>>/dev/null

docker start sql_$srv_prefix 1>>/dev/null






echo -e "${RED}==> ${YELLOW}Wait sql_${srv_prefix}...${NC}"

progress_bar start
for ((k=1; k < 300; k++))
do
	progress_bar work
done
progress_bar stop






# MSSQL password test
echo -e "${RED}==> ${YELLOW}MSSQL password test...${NC}"

sql_pw_test=`docker exec sql_${srv_prefix} /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U sa -P ${mssql_pass} -Q "SET NOCOUNT ON;SELECT 1" -h -1 | sed s/' '//g 2>>/dev/null`
if [[ ! "$sql_pw_test" == "1" ]]; then
	echo -e "\n${BLUE}Failed to set password for MS SQL Server.${NC}"
	echo -e "${BLUE}Check your password - it may contain unsupported special characters.${NC}"
	echo -e "${BLUE}Details:${NC}"
	echo -e "https://learn.microsoft.com/en-us/sql/relational-databases/security/strong-passwords?view=sql-server-ver15"
	echo
	echo -e "${BLUE}Rolling back changes...${NC}\n"
	
	docker stop sql_$srv_prefix 1>>/dev/null
	docker rm sql_$srv_prefix 1>>/dev/null
	/bin/bash -c "rm -rf /home/data_$srv_prefix"
	/bin/bash -c "rm -rf /var/opt/mssql/data_$srv_prefix"
	exit 0
fi






# Changing the name of the database user
if [[ $mssql_user != "sa" && $mssql_user != "SA" ]]; then
	echo -e "${RED}==> ${YELLOW}Changing the name of the database user...${NC}"
	docker exec -it sql_${srv_prefix} /bin/bash -c "cat > /tmp/sql_user_tmp.sql <<EOF
USE [master]
ALTER LOGIN sa WITH NAME=${mssql_user}
GO
EOF"
	mssqlConn="/opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U sa -P ${mssql_pass}"
	docker exec -it sql_${srv_prefix} ${mssqlConn} -i /tmp/sql_user_tmp.sql 1>>/dev/null
	docker exec -it sql_${srv_prefix} /bin/bash -c "rm -f /tmp/sql_user_tmp.sql"
	
	echo -e "${RED}==> ${YELLOW}MSSQL username test...${NC}"
	sql_user_test=`docker exec sql_${srv_prefix} /opt/mssql-tools/bin/sqlcmd -S 127.0.0.1 -U ${mssql_user} -P ${mssql_pass} -Q "SET NOCOUNT ON;SELECT 1" -h -1 | sed s/' '//g 2>>/dev/null`
	if [[ ! "$sql_user_test" == "1" ]]; then
		echo -e "\n${BLUE}Failed to set username for MS SQL Server.${NC}"
		echo -e "${BLUE}Check your username - it may contain unsupported special characters.${NC}\n"
		echo -e "${BLUE}Rolling back changes...${NC}\n"
		
		docker stop sql_$srv_prefix 1>>/dev/null
		docker rm sql_$srv_prefix 1>>/dev/null
		/bin/bash -c "rm -rf /home/data_$srv_prefix"
		/bin/bash -c "rm -rf /var/opt/mssql/data_$srv_prefix"
		exit 0
	fi
fi






echo -e "${RED}==> ${YELLOW}Run cabal_${srv_prefix}...${NC}"

docker run -d \
--name cabal_$srv_prefix \
--link sql_$srv_prefix:sql_$srv_prefix \
-e "MSSQL_HOST=sql_$srv_prefix" \
-e "MSSQL_PORT=1433" \
-e "MSSQL_USER=$mssql_user" \
-e "MSSQL_PASS=$mssql_pass" \
-e "CABAL_HOST=$host_addr" \
-p ${port_range}:${port_range} \
--restart=$restart \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-v /home/data_${srv_prefix}/cabal:/etc/cabal \
-v /home/data_${srv_prefix}/cabal_bin:/etc/cabal_bin \
-v /home/data_${srv_prefix}/cabal_scripts:/etc/cabal_scripts \
-v /home/data_${srv_prefix}/cabal_structure:/etc/cabal_structure \
-v /home/data_${srv_prefix}/logs:/var/log/cabal \
-v /etc/localtime:/etc/localtime:ro \
$cabal_container 1>>/dev/null

sleep 5
#odbc.ini
docker exec -it cabal_$srv_prefix /bin/bash -c "ln -sf /etc/cabal_scripts/odbc/odbc.ini /etc/odbc.ini"
docker exec -it cabal_$srv_prefix /bin/bash -c "ln -sf /etc/cabal_scripts/odbc/odbcinst.ini /etc/odbcinst.ini"

docker exec -it cabal_$srv_prefix chmod 0700 /etc/cabal_scripts/init.sh
docker exec -it cabal_$srv_prefix /etc/cabal_scripts/init.sh

sed -i -e "s/^Address.*/Address     = sql_$srv_prefix/g" /home/data_${srv_prefix}/cabal_scripts/odbc/odbc.ini
sed -i -e "s/^Port.*/Port        = 1433/g" /home/data_${srv_prefix}/cabal_scripts/odbc/odbc.ini




# Configuring cabal ports
echo -e "${RED}==> ${YELLOW}Configuring cabal ports in INI files...${NC}"
sleep 1

# xxx01 - AgentShop
# xxx02 - ChatNodePort
# xxx03-10 - LoginSvrPort
# xxx11-30 - WorldSvr

# xxx51 - AgentShop 2
# xxx52 - ChatNodePort 2
# xxx53-60 - LoginSvrPort 2
# xxx61-80 - WorldSvr 2

AgentShopPort=${cabal_port}
ChatNodePort=$(($cabal_port+1))
LoginSvrPort=$(($cabal_port+2))
WorldSvrPort=$(($cabal_port+10))

AgentShop2Port=$(($cabal_port+50))
ChatNode2Port=$(($cabal_port+51))
WorldSvr2Port=$(($cabal_port+60))

sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$AgentShopPort/g" /home/data_${srv_prefix}/cabal/AgentShop_01.ini
sed -i -e "/\[ChatNode\]/,/\[/ s/^Port=.*/Port=$ChatNodePort/g" /home/data_${srv_prefix}/cabal/AgentShop_01.ini
sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$ChatNodePort/g" /home/data_${srv_prefix}/cabal/ChatNode_01.ini
sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$LoginSvrPort/g" /home/data_${srv_prefix}/cabal/LoginSvr_01.ini

sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$AgentShop2Port/g" /home/data_${srv_prefix}/cabal/AgentShop_02.ini 2>>/dev/null
sed -i -e "/\[ChatNode\]/,/\[/ s/^Port=.*/Port=$ChatNode2Port/g" /home/data_${srv_prefix}/cabal/AgentShop_02.ini 2>>/dev/null
sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$ChatNode2Port/g" /home/data_${srv_prefix}/cabal/ChatNode_02.ini 2>>/dev/null


ws_list=`ls /home/data_${srv_prefix}/cabal | grep WorldSvr_01`
for daemon_file in $ws_list
do
	tmp=${daemon_file#*_}
	tmp=${tmp%.*}
	tmp=${tmp#*_}
	tmp=`echo $tmp | awk '$0*=1'`
	wport=$(($WorldSvrPort+$tmp-1))

	sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$wport/g" /home/data_${srv_prefix}/cabal/${daemon_file}
	sed -i -e "/\[ChatNode\]/,/\[/ s/^Port=.*/Port=$ChatNodePort/g" /home/data_${srv_prefix}/cabal/${daemon_file}
	sed -i -e "/\[AgentShop\]/,/\[/ s/^Port=.*/Port=$AgentShopPort/g" /home/data_${srv_prefix}/cabal/${daemon_file}
done

ws_list=`ls /home/data_${srv_prefix}/cabal | grep WorldSvr_02`
for daemon_file in $ws_list
do
	tmp=${daemon_file#*_}
	tmp=${tmp%.*}
	tmp=${tmp#*_}
	tmp=`echo $tmp | awk '$0*=1'`
	wport=$(($WorldSvr2Port+$tmp-1))

	sed -i -e "/\[NetLib\]/,/\[/ s/^Port=.*/Port=$wport/g" /home/data_${srv_prefix}/cabal/${daemon_file}
	sed -i -e "/\[ChatNode\]/,/\[/ s/^Port=.*/Port=$ChatNode2Port/g" /home/data_${srv_prefix}/cabal/${daemon_file}
	sed -i -e "/\[AgentShop\]/,/\[/ s/^Port=.*/Port=$AgentShop2Port/g" /home/data_${srv_prefix}/cabal/${daemon_file}
done



if [[ $KeepDPTime -ne 0 ]];then
	sed -i -e "s/^KeepDPTime=.*/KeepDPTime=$KeepDPTime/g" /home/data_${srv_prefix}/cabal/WorldSvr_*
fi
if [[ $MaxDPLimit -ne 0 ]];then
	sed -i -e "s/^MaxDPLimit=.*/MaxDPLimit=$MaxDPLimit/g" /home/data_${srv_prefix}/cabal/WorldSvr_*
fi
if [[ $MaxPoint -ne 0 ]];then
	sed -i -e "s/^MaxPoint=.*/MaxPoint=$MaxPoint/g" /home/data_${srv_prefix}/cabal/WorldSvr_*
fi
if [[ $BasisPoint -ne 0 ]];then
	sed -i -e "s/^BasisPoint=.*/BasisPoint=$BasisPoint/g" /home/data_${srv_prefix}/cabal/WorldSvr_*
fi
if [[ $UpdateSpan -ne 0 ]];then
	sed -i -e "s/^UpdateSpan=.*/UpdateSpan=$UpdateSpan/g" /home/data_${srv_prefix}/cabal/WorldSvr_*
fi

sed -i -e "s/IPAddress=.*/IPAddress=$host_addr/g" /home/data_${srv_prefix}/cabal/WorldSvr*
sed -i -e "s/AddrForClient=.*/AddrForClient=$host_addr/g" /home/data_${srv_prefix}/cabal/WorldSvr*






# Database creation
/usr/bin/create_dbs $srv_prefix






# Restoring databases from backup
echo -e "${RED}==> ${YELLOW}Restoring databases from backup...${NC}"
sleep 1
/usr/bin/restore_dbs $srv_prefix -f






# Set cron server id
echo -e "${RED}==> ${YELLOW}Adding Schedules to the Cron Scheduler...${NC}"
sleep 1
old_pref=`grep -m1 "server_id=" /home/data_${srv_prefix}/cabal_structure/crontab | grep -oP '=\K.*'`
sed -i "s/ ${old_pref}/ ${srv_prefix}/g" /home/data_${srv_prefix}/cabal_structure/crontab
sed -i "s/=${old_pref}/=${srv_prefix}/g" /home/data_${srv_prefix}/cabal_structure/crontab
ln -sf /home/data_${srv_prefix}/cabal_structure/crontab /etc/cron.d/cabal_${srv_prefix}_cron

echo -e "\n${GREEN}Server creation completed\n${NC}"
