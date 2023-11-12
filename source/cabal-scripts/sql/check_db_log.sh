#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# check_db_log main

check_container_exists $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

get_mssql_conn $1
get_db_list db $1

queryFile="db_logfile.sql"
tmpFile=`docker exec sql_${1} mktemp`

maximumsize=$(( 10 * 1024 * 1024 * 1024 )) # 10 GB MAX
shrink_flag=0
for db_name in $dbs
do
	docker cp ${queriesDir}${queryFile} sql_${1}:${tmpFile}
	docker exec sql_${1} sed -i "s/<DB_NAME>/${db_name}/g" ${tmpFile}
	logtest=`docker exec sql_${1} ${mssqlConn} -i ${tmpFile} -h -1 | tr " " "\n"`
	logtest=$(basename $logtest)
	logtest=/var/opt/mssql/data_$1/$logtest
	if [ -f $logtest ]; then
		actualsize=$(wc -c <"$logtest")
		if [[ $actualsize -ge $maximumsize ]]; then
			shrink_flag=1
		fi
		#echo "$db_name - $logtest - $actualsize"
	fi
done
docker exec sql_${1} /bin/bash -c "rm -f ${tmpFile}"

if [[ $shrink_flag == 1 ]]; then
	/usr/bin/shrink_dbs $1 -dt
fi
