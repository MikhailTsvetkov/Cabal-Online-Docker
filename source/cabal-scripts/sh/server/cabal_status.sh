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

echo -e "\n${GREEN}..-----Status of Cabal services------..${NC}"
docker exec -it cabal_$1 /bin/bash -c "/etc/cabal_scripts/status.sh -s $2"

. /home/data_$1/cabal_structure/backup_conf
if [[ $autobackup -eq 0 ]]; then
	echo -e "\n${RED}Warning!${NC} Autobackup disabled!"
	echo -e "Use ${PINK}autobackup $1 on${NC} to enable this.\n"
fi
