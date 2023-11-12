#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh
. /home/data_$1/cabal_structure/backup_conf

if [[ $autobackup -eq 0 ]]; then
	exit 0
fi

cabal_create_backup hourly $1 -dt
