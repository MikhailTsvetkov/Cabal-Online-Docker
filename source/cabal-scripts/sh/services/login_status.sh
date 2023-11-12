#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

get_server_num $2
if [[ $snum -eq 0 ]]; then
	snum="01"
fi

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

daemon=LoginSvr_$snum

docker exec cabal_$1 /bin/bash -c "/etc/cabal_scripts/status.sh $daemon"
