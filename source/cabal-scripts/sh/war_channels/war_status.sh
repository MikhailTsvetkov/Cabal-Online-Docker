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

echo -e "\n${GREEN}..-------Status of Nation War--------..${NC}"
docker exec -it cabal_$1 /bin/bash -c "/etc/cabal_scripts/status.sh -w $2"
