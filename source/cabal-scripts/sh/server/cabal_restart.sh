#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

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


/usr/bin/cabal_stop $1 $2 $3

if [[ $2 == '' || $2 == '-dt' ]]; then
	if ! [ -d /home/data_${1}/logs/backups ]; then
		mkdir /home/data_${1}/logs/backups
	fi

	if compgen -G "/home/data_${1}/logs/*.log" > /dev/null; then
		cd /home/data_${1}/logs/
		tar -czf backups/$(formatted_date).tar.gz *.log
	fi

	rm -f /home/data_${1}/logs/*.log /home/data_${1}/logs/*.trc
fi

/usr/bin/cabal_start $1 $2 $3
