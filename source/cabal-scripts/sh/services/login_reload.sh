#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

get_server_num $2
if [[ $snum -eq 0 ]]; then
	snum="01"
fi

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

daemon=LoginSvr_$snum

cabal_service reload $1 $daemon $dt
