#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# reset_online main 0 Account -dt
# reset_online main 1 Server01 -dt

check_container_exists $1 $4
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running sql $1 $4
if [[ $? -eq 1 ]]; then
	exit 0
fi

get_mssql_conn $1

if [[ $2 -eq 0 ]]; then
	docker exec sql_${1} ${mssqlConn} -Q "UPDATE [$3].[dbo].[cabal_auth_table] SET [Login]=0" -r1 2>>/dev/null 1>>/dev/null
fi
if [[ $2 -eq 1 ]]; then
	docker exec sql_${1} ${mssqlConn} -Q "UPDATE [$3].[dbo].[cabal_character_table] SET [Login]=0" -r1 2>>/dev/null 1>>/dev/null
fi
