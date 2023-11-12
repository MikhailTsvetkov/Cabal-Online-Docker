#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh


check_container_exists $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
rm -f /home/data_${1}/logs/*.trc


check_container_running cabal $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
docker exec cabal_${1} /bin/bash -c 'rm -f /etc/cabal_etc/core/*'
docker exec cabal_${1} /bin/bash -c 'rm -f /core.*'
