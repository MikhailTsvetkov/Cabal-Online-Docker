#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

port=`grep -m1 -w "Port" /home/data_${1}/cabal/AuthDBAgent.ini | cut -d "=" -f 2`
ping=`docker exec cabal_$1 nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
if [[ $ping -eq 1 ]]; then
	exit 0
fi

echo 0 > /home/data_${1}/cabal_scripts/services_checker/GlobalMgrSvr
docker exec cabal_$1 supervisorctl restart GlobalMgrSvr
sleep 12
echo 1 > /home/data_${1}/cabal_scripts/services_checker/GlobalMgrSvr
