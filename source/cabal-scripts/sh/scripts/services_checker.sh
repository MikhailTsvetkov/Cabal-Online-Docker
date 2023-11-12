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

sleep 15
docker exec cabal_${1} /etc/cabal_scripts/services_checker.sh
