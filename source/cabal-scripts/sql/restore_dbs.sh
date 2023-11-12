#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# restore_dbs main

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

echo -e "\n${YELLOW}Restoring the Database from a backup (/home/data_${1}/mssql/backup)${NC}"

get_mssql_conn $1
get_db_list db $1

if [[ ! $2 == "-f" ]]; then
	echo -e "\n${PINK}All Databases will be overwritten!${NC}"
	echo -e -n "${PINK}You are sure? [Y]/[N]: ${NC}"
	read ready
	if [[ ! $ready == "Y" && ! $ready == "y" ]]; then
		echo -e "\n${YELLOW}Database recovery aborted\n${NC}"
		exit 0
	fi
fi
	
for db_name in $dbs
do
	echo -e "\n${BLUE} • Restore $db_name database...\n${NC}"
	cabal_db restore $1 $db_name
	echo -e "\n${GREEN}---------------------------------------------------------------${NC}"
done
echo -e "\n${GREEN}Database recovery completed\n${NC}"
