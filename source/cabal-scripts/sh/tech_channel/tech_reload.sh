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

daemons=`cat /home/data_${1}/cabal_structure/tech_channel | grep -v ^#`
for daemon in $daemons
do
	if [[ $snum -eq 0 ]]; then
		cabal_service reload $1 $daemon $dt
	else
		if [[ $daemon = WorldSvr_${snum}_* ]]; then
			cabal_service reload $1 $daemon $dt
		fi
	fi
done
