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

if [[ ! $2 == '-dt' ]]; then
	echo -e "\n${GREEN}..-------Reload Proxy services-------..${NC}"
fi

/bin/bash -c 'rm -f /home/data_${1}/cabal_scripts/services_checker/proxy_*'
docker exec cabal_${1} supervisorctl stop gms_proxy:*

cat -T /home/data_${1}/cabal_structure/proxy_list | egrep -v "(^\[|^#)" | while read ln
do
	ln=${ln//'^I'/':'}
	ln=${ln//' '/':'}
	gmsId=`echo $ln | cut -d ":" -f1`
	gmsPort=`echo $ln | cut -d ":" -f2`
	if [[ $gmsPort != '' && $gmsPort -gt 0 && $gmsPort -le 65535 ]]; then
		if [[ $gmsId -lt 10 ]]; then
			gmsId="0${gmsId}"
		fi
		cabal_service startProxy $1 $gmsId $2
		
		echo 1 > /home/data_${1}/cabal_scripts/services_checker/proxy_$gmsId
	fi
done
