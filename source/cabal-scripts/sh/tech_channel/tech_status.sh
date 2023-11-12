#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $1
if [[ $? -eq 1 ]]; then
	exit 0
fi


daemons=`cat /home/data_${1}/cabal_structure/tech_channel | grep -v ^#`
for daemon in $daemons
do
	docker exec -it cabal_$1 /bin/bash -c "/etc/cabal_scripts/status.sh $daemon"
done
