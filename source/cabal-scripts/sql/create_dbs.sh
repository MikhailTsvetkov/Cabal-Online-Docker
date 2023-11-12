#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# create_dbs main

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

echo -e "${RED}==> ${YELLOW}Databases creation...${NC}"

get_db_list file $1

for db_name in $dbs
do
	echo -e "\n${BLUE} • Creation $db_name database...\n${NC}"
	cabal_db create $1 $db_name
	echo -e "\n${GREEN}---------------------------------------------------------------${NC}"
done

echo -e "\n${GREEN}Database creation completed\n${NC}"
