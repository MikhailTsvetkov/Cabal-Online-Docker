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


if [[ ! $dt == '-dt' ]]; then
	echo -e "\n${GREEN}..------Stopping Cabal services------..${NC}"
fi

daemons=`tac /home/data_${1}/cabal_structure/server_list | grep -v ^#`
for daemon in $daemons
do
	if [[ $snum -eq 0 ]]; then
		echo 0 > /home/data_${1}/cabal_scripts/services_checker/$daemon
		cabal_service stop $1 $daemon $dt
	else
		if [[ $daemon = WorldSvr_${snum}_* || $daemon = "DBAgent_$snum" || $daemon = "CashDBAgent_$snum" || $daemon = "PartySvr_$snum" || $daemon = "ChatNode_$snum" || $daemon = "AgentShop_$snum" ]]; then
			echo 0 > /home/data_${1}/cabal_scripts/services_checker/$daemon
			cabal_service stop $1 $daemon $dt
		fi
	fi
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
done

docker exec cabal_${1} /bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'
