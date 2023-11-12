#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# cabal_db create main Server01 -dt
# create | remove | restore | backup | shrink | setflag

check_container_exists $2 $4
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $2 $4
if [[ $? -eq 1 ]]; then
	exit 0
fi

get_mssql_conn $2

queryFile="db_${1}.sql"
tmpFile=`docker exec sql_${2} mktemp`

docker cp ${queriesDir}${queryFile} sql_${2}:${tmpFile}
docker exec sql_${2} sed -i "s/<DB_NAME>/${3}/g" ${tmpFile}
docker exec sql_${2} ${mssqlConn} -i ${tmpFile}

docker exec sql_${2} /bin/bash -c "rm -f ${tmpFile}"

get_db_list db $2
