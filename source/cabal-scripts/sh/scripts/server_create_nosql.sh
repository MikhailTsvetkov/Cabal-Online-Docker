#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

. /home/_server_data/new_server.conf
cabal_container='mikhailtsvetkov/hardcore-cabal-server:3.1.0'
#cabal_container='hardcore-cabal-server:latest'
cabal_port=35001






echo -e "\n${RED}==> ${YELLOW}Checking the configuration...${NC}"


# Get server IP
host_addr=`hostname -I | awk '{print $1;}'`


# Check server id
screate_check_cont_name $srv_prefix
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







echo -e "${RED}==> ${YELLOW}Run cabal_${srv_prefix}...${NC}"

docker run -d \
--name cabal_$srv_prefix \
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








# Set cron server id
echo -e "${RED}==> ${YELLOW}Adding Schedules to the Cron Scheduler...${NC}"
sleep 1
old_pref=`grep -m1 "server_id=" /home/data_${srv_prefix}/cabal_structure/crontab | grep -oP '=\K.*'`
sed -i "s/ ${old_pref}/ ${srv_prefix}/g" /home/data_${srv_prefix}/cabal_structure/crontab
sed -i "s/=${old_pref}/=${srv_prefix}/g" /home/data_${srv_prefix}/cabal_structure/crontab
ln -sf /home/data_${srv_prefix}/cabal_structure/crontab /etc/cron.d/cabal_${srv_prefix}_cron

echo -e "\n${GREEN}Server creation completed\n${NC}"
