#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

case $2 in
	on)
		sed -i -e "s/^autobackup=.*/autobackup=1/g" /home/data_${1}/cabal_structure/backup_conf
		echo -e "${YELLOW}Autobackup for $1 server is enabled.${NC}"
		;;
	off)
		sed -i -e "s/^autobackup=.*/autobackup=0/g" /home/data_${1}/cabal_structure/backup_conf
		echo -e "${YELLOW}Autobackup for $1 server is disabled.${NC}"
		;;
esac
