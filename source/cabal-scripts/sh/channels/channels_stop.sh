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

daemonsStop=`tac /home/data_${1}/cabal_structure/channels_list | grep -v ^#`

if [[ ! $dt == '-dt' ]]; then
	echo -e "\n${GREEN}..-----Stopping World channels-----..${NC}"
fi

for daemon in $daemonsStop
do
	if [[ $snum -eq 0 ]]; then
		echo 0 > /home/data_${1}/cabal_scripts/services_checker/$daemon
		cabal_service stop $1 $daemon $dt
	else
		if [[ $daemon = WorldSvr_${snum}_* ]]; then
			echo 0 > /home/data_${1}/cabal_scripts/services_checker/$daemon
			cabal_service stop $1 $daemon $dt
		fi
	fi
done

docker exec cabal_${1} /bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'
