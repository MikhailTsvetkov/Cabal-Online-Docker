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


if [[ ! $dt == '-dt' ]]; then
	echo -e "\n${GREEN}..-----Starting World channels-----..${NC}"
fi

daemons=`cat /home/data_${1}/cabal_structure/channels_list | grep -v ^#`
for daemon in $daemons
do
	# Single server
	if [[ $snum -eq 0 ]]; then
		chport=`grep -m1 -w "Port" /home/data_${1}/cabal/${daemon}.ini | cut -d "=" -f 2`
		/usr/bin/anticrash $chport
		
		cabal_service start $1 $daemon $dt
		
		echo 1 > /home/data_${1}/cabal_scripts/services_checker/$daemon
	else
		if [[ $daemon = WorldSvr_${snum}_* ]]; then
			chport=`grep -m1 -w "Port" /home/data_${1}/cabal/${daemon}.ini | cut -d "=" -f 2`
			/usr/bin/anticrash $chport
		
			cabal_service start $1 $daemon $dt
			
			#countdown "00:00:12"
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
