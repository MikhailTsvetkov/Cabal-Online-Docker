#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

check_container_exists $1
if [[ $? -eq 1 ]]; then
	exit 0
fi

if [[ $2 == "" || $3 == "" ]] ; then
	echo -e "\n${RED}You must specify the sql user as the second argument and password as the third argument${NC}"
	echo -e "${YELLOW}For example set_sql_access main sa YourStr0ngPWD${NC}"
	exit 0
fi


sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/AuthDBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/AuthDBAgent*

sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/CashDBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/CashDBAgent*

sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/DBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/DBAgent*

sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/EventDBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/EventDBAgent*

sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/GlobalDBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/GlobalDBAgent*

sed -i -e "s/DBId=.*/DBId=$2/g" /home/data_$1/cabal/PCBangDBAgent*
sed -i -e "s/DBPwd=.*/DBPwd=$3/g" /home/data_$1/cabal/PCBangDBAgent*

