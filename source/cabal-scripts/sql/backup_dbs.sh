#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# backup_dbs main -s -dt

check_container_exists $1 $3
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1 $3
if [[ $? -eq 1 ]]; then
	exit 0
fi

if [[ ! $3 == "-dt" ]] ; then
	echo -e "${RED}==> ${YELLOW}Databases are being backed up${NC}"
fi

get_mssql_conn $1
get_db_list db $1

if ! [ -d /home/data_${1}/mssql/prev_backups ]; then
	mkdir -p /home/data_${1}/mssql/prev_backups
fi
/bin/bash -c "cp -a -f /home/data_${1}/mssql/backup /home/data_${1}/mssql/prev_backups"
/bin/bash -c "rm -f /home/data_${1}/mssql/backup/*"

for db_name in $dbs
do
	if [[ ! $3 == "-dt" ]] ; then
		echo -e "\n${BLUE} • Backup $db_name database...\n${NC}"
	fi
	cabal_db backup $1 $db_name $3
	if [[ ! $3 == "-dt" ]] ; then
		echo -e "\n${GREEN}---------------------------------------------------------------${NC}"
	fi
done

echo
if [[ ! $2 == "-s" ]] ; then
	if [[ ! $3 == "-dt" ]] ; then
		echo -e "${BLUE} • Backup archiving...\n${NC}"
	fi
	if ! [ -d /home/_server_backups ]; then
		mkdir /home/_server_backups
	fi
	bkp=/home/_server_backups/db_${1}_backup_`date "+%Y.%m.%d_%H-%M-%S"`.tar.gz
	cd /home/data_${1}/mssql/backup
	tar cfz $bkp *
	if [[ ! $3 == "-dt" ]] ; then
		echo -e "${YELLOW}The backup is saved as $bkp${NC}"
	fi
fi
if [[ ! $3 == "-dt" ]] ; then
	echo -e "${YELLOW}Database backups are saved in /home/data_${1}/mssql/backup\n${NC}"
fi
