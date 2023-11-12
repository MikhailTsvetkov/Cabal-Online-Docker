#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

get_server_num $2

if [[ $2 == '-dt' || $3 == '-dt' ]]; then
	dt='-dt'
fi

check_container_exists $1 $dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $1 $dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

find /home/data_${1}/cabal_bin -type f -print0 | xargs -0 -r -n 100 -P 6 chmod 0700

# Enable Checker
docker exec cabal_$1 /bin/bash -c 'rm -f /etc/cabal_scripts/services_checker/*'
docker exec cabal_$1 /bin/bash -c 'echo "checker_status=1" > /etc/cabal_etc/services_checker_status'

# Run proxy
/usr/bin/gms_proxy_reexec $1 $dt


if [[ ! $dt == '-dt' ]]; then
	echo -e "\n${GREEN}..------Starting Cabal services------..${NC}"
fi

daemons=`cat /home/data_${1}/cabal_structure/world_list | grep -v ^#`
for daemon in $daemons
do
	if [[ $daemon = GlobalDBAgent* || $daemon = DBAgent* ]]; then
		pathToIniFile="/home/data_${1}/cabal/${daemon}.ini"
		sectionContent=$(sed -n '/^\[DBAgent\]/,/^\[/p' $pathToIniFile | sed -e '/^\[/d' | sed -e '/^$/d')
		DSN=$(getValueFromINI "$sectionContent" "DSN")
		pathToIniFile="/home/data_${1}/cabal_scripts/odbc/odbc.ini"
		sectionContent=$(sed -n "/^\[${DSN}\]/,/^\[/p" $pathToIniFile | sed -e '/^\[/d' | sed -e '/^$/d' | sed -e 's/[[:space:]]*//g')
		targetDB=$(getValueFromINI "$sectionContent" "Database")
	fi
	if [[ $daemon = GlobalDBAgent* ]]; then
		/usr/bin/reset_online $1 0 $targetDB
	fi
	if [[ $daemon = DBAgent* ]]; then
		/usr/bin/reset_online $1 1 $targetDB
	fi
	
	# Single server
	if [[ $snum -eq 0 ]]; then
		if [[ $daemon = WorldSvr* || $daemon = ChatNode_* || $daemon = AgentShop_* || $daemon = LoginSvr_* ]]; then
			chport=`grep -m1 -w "Port" /home/data_${1}/cabal/${daemon}.ini | cut -d "=" -f 2`
			/usr/bin/anticrash $chport
		fi
		
		cabal_service start $1 $daemon $dt
		
		echo 1 > /home/data_${1}/cabal_scripts/services_checker/$daemon
		
	# Multi server
	else
		if [[ $daemon = WorldSvr_${snum}_* || $daemon = "DBAgent_$snum" || $daemon = "CashDBAgent_$snum" || $daemon = "PartySvr_$snum" || $daemon = "ChatNode_$snum" || $daemon = "AgentShop_$snum" ]]; then
			if [[ $daemon = WorldSvr_${snum}_* || $daemon = ChatNode_* || $daemon = AgentShop_* || $daemon = LoginSvr_* ]]; then
				chport=`grep -m1 -w "Port" /home/data_${1}/cabal/${daemon}.ini | cut -d "=" -f 2`
				/usr/bin/anticrash $chport
			fi
		
			cabal_service start $1 $daemon $dt
			
			echo 1 > /home/data_${1}/cabal_scripts/services_checker/$daemon
		fi
	fi
done
docker exec cabal_${1} /bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'

. /home/data_$1/cabal_structure/backup_conf
if [[ $autobackup -eq 0 && ! $dt == '-dt' ]]; then
	echo -e "\n${RED}Warning!${NC} Autobackup disabled!"
	echo -e "Use ${PINK}autobackup $1 on${NC} to enable this.\n"
fi
