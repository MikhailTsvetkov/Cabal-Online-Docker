#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

get_server_num $2

check_container_exists $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

check_gms $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

find /home/data_${1}/cabal_bin -type f -print0 | xargs -0 -r -n 100 -P 6 chmod 0700

if [[ $snum -gt 0 && $3 -gt 0 ]]; then
	if [[ $3 -lt 10 ]]; then
		chnum="0$3"
	else
		chnum="$3"
	fi
	chport=`grep -m1 -w "Port" /home/data_${1}/cabal/WorldSvr_${snum}_${chnum}.ini | cut -d "=" -f 2`
	/usr/bin/anticrash $chport
	docker exec cabal_$1 supervisorctl restart WorldSvr_${snum}_${chnum}
else
	daemons=`tac /home/data_${1}/cabal_structure/war_list | grep -v ^#`

	for daemon in $daemons
	do
		chport=`grep -m1 -w "Port" /home/data_${1}/cabal/${daemon}.ini | cut -d "=" -f 2`
		/usr/bin/anticrash $chport
		docker exec cabal_$1 supervisorctl restart ${daemon}
	done
fi

docker exec cabal_${1} /bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'
