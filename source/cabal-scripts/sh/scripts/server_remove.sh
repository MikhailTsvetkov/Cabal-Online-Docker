#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

echo -e "${YELLOW}A backup of the database and server files will be created for ${1}.${NC}"
echo -e "${YELLOW}The sql_${1} and cabal_${1} containers will be removed.${NC}"
echo -e "${YELLOW}The /home/data_${1} directory will be removed.${NC}"

echo -e -n "\n${PINK}Continue? [Y]/[N]: ${NC}"
read ready
if [[ -z $ready || ($ready != "y" && $ready != "Y") ]]; then
	echo -e "${BLUE}Aborted${NC}\n"
	exit 0
fi

# Create sql backup
echo -e -n "\n${PINK}Create a fresh database backup? [Y]/[N]: ${NC}"
read ready
while [[ -z $ready ]]
do
	echo -e -n "\n${PINK}Create a fresh database backup? [Y]/[N]: ${NC}"
	read ready
done
if [[ $ready != "n" && $ready != "N" ]]; then
	db_bk=1
	check_container_running sql $1 -dt
	if [[ $? -eq 1 ]]; then
		echo -e "${BLUE}The sql_${1} container is currently off.${NC}"
		echo -e "${BLUE}You need to start it to create a database backup.${NC}"
		echo -e -n "\n${PINK}Start sql_${1} container? [Y]/[N]: ${NC}"
		read ready
		while [[ -z $ready ]]
		do
			echo -e -n "\n${PINK}Start sql_${1} container? [Y]/[N]: ${NC}"
			read ready
		done
		if [[ $ready != "n" && $ready != "N" ]]; then
			docker start sql_${1} 1>>/dev/null
			progress_bar start
			for ((k=1; k < 300; k++))
			do
				progress_bar work
			done
			progress_bar stop
			check_container_running sql $1 -dt
			if [[ $? -eq 1 ]]; then
				echo -e "${YELLOW}Failed to start container sql_${1}.${NC}"
				echo -e -n "\n${PINK}Continue anyway? [Y]/[N]: ${NC}"
				read ready
				while [[ -z $ready ]]
				do
					echo -e -n "\n${PINK}Continue anyway? [Y]/[N]: ${NC}"
					read ready
				done
				if [[ -z $ready || ($ready != "y" && $ready != "Y") ]]; then
					echo -e "${BLUE}Aborted${NC}\n"
					exit 0
				else
					db_bk=0
				fi
			fi
		else
			db_bk=0
		fi
	fi
else
	db_bk=0
fi
if [[ $db_bk -eq 1 ]]; then
	echo -e "${RED}==> ${YELLOW}Create a database backup...${NC}"
	/usr/bin/backup_dbs $1 -s
	sleep 1
fi

echo -e "${RED}==> ${YELLOW}Copying the files...${NC}"
cabal_create_backup removed_servers $1 -dt
/bin/bash -c "rm -f /etc/cron.d/cabal_${1}_cron"

echo -e "${RED}==> ${YELLOW}Stopping the cabal_${1} container...${NC}"
docker stop cabal_${1} 1>>/dev/null
echo -e "${RED}==> ${YELLOW}Stopping the sql_${1} container...${NC}"
docker stop sql_${1} 1>>/dev/null
echo -e "${RED}==> ${YELLOW}Removing the cabal_${1} container...${NC}"
docker rm cabal_${1} 1>>/dev/null
echo -e "${RED}==> ${YELLOW}Removing the sql_${1} container...${NC}"
docker rm sql_${1} 1>>/dev/null


echo -e "${RED}==> ${YELLOW}Removing /home/data_${1} directory...${NC}"
/bin/bash -c "rm -rf /home/data_${1}"

echo -e "${RED}==> ${YELLOW}Removing /var/opt/mssql/data_${1} directory...${NC}"
/bin/bash -c "rm -rf /var/opt/mssql/data_${1}"

sync; echo 1 > /proc/sys/vm/drop_caches
echo -e "\n${GREEN}Server $1 has been removed.${NC}\n"
