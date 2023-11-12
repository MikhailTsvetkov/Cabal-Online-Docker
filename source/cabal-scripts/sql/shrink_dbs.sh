#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# shrink_dbs main -dt

check_container_exists $1 $2
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1 $2
if [[ $? -eq 1 ]]; then
	exit 0
fi

if [[ ! $2 == "-dt" ]] ; then
	echo -e "\n${YELLOW}Compressing the databases logs${NC}"
fi

get_mssql_conn $1
get_db_list db $1

for db_name in $dbs
do
	if [[ ! $2 == "-dt" ]] ; then
		echo -e "\n${BLUE} • Shrinking $db_name database...\n${NC}"
	fi
	cabal_db shrink $1 $db_name $2
	if [[ ! $2 == "-dt" ]] ; then
		echo -e "\n${GREEN}---------------------------------------------------------------${NC}"
	fi
done
