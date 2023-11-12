#!/bin/bash

DEBUG=0
RECHECK_INTERVAL=10

. /etc/cabal_etc/services_checker_status
if [[ $checker_status -eq 0 ]]; then
	exit 0
fi

echo "checker_status=0" > /etc/cabal_etc/services_checker_status

#Check proxy
# cat -T /etc/cabal_structure/proxy_list | egrep -v "(^\[|^#)" | while read ln
# do
# 	ln=${ln//'^I'/':'}
# 	ln=${ln//' '/':'}
# 	gmsId=`echo $ln | cut -d ":" -f1`
# 	gmsPort=`echo $ln | cut -d ":" -f2`
# 	Item=`echo $ln | cut -d ":" -f3`
# 	Mobs=`echo $ln | cut -d ":" -f4`
# 	DT=`date "+%a %b %d %Y %H:%M:%S"`
# 	if [[ $gmsPort != '' && $gmsPort -gt 0 && $gmsPort -le 65535 ]]; then
# 		chk=`head -n1 /etc/cabal_scripts/services_checker/proxy_$gmsId | tr -s '\n' ' '`
# 		if [[ $chk -eq 1 ]]; then
# 			ping=`nmap 127.0.0.1 -p $gmsPort | grep -q "/tcp *open " || echo 1`
# 			if [[ $ping -eq 1 ]]; then
# 				echo "[$DT]: [##NOTICE##] gms_proxy_$gmsId [$gmsPort] is crashed. Restarting." >> /var/log/cabal/services_checker.log
# 				supervisorctl restart gms_proxy_$gmsId >/dev/null 2>/dev/null
# 			else
# 				if [[ $DEBUG -eq 1 ]]; then
# 					echo "[$DT]: gms_proxy_$gmsId [$gmsPort] is running" >> /var/log/cabal/services_checker.log
# 				fi
# 			fi
# 		else
# 			if [[ $DEBUG -eq 1 ]]; then
# 				echo "[$DT]: gms_proxy_$gmsId [$gmsPort] is stopped" >> /var/log/cabal/services_checker.log
# 			fi
# 		fi
# 	fi
# done

# Check Cabal services
daemons=`cat /etc/cabal_structure/world_list | grep -v ^#`
for daemon in $daemons
do
	DT=`date "+%a %b %d %Y %H:%M:%S"`
	chk=`head -n1 /etc/cabal_scripts/services_checker/$daemon | tr -s '\n' ' '`
	if [[ $chk -eq 1 ]]; then
		port=`grep -m1 -w "Port" /etc/cabal/${daemon}.ini | cut -d "=" -f 2`
		ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
		if [[ $ping -eq 1 ]]; then
			echo "[$DT]: [##WARNING##] ${daemon} daemon is crashed. Recheck after $RECHECK_INTERVAL seconds." >> /var/log/cabal/services_checker.log
			sleep $RECHECK_INTERVAL
			ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
			if [[ $ping -eq 1 ]]; then
				DT=`date "+%a %b %d %Y %H:%M:%S"`
				supervisorctl restart ${daemon} >/dev/null 2>/dev/null
				echo "[$DT]: Restarting ${daemon} daemon" >> /var/log/cabal/services_checker.log
				if [[ $daemon == "GlobalMgrSvr" || $daemon == WorldSvr* ]]; then
					sleep 12
				fi
			fi
		else
			if [[ $DEBUG -eq 1 ]]; then
				echo "[$DT]: ${daemon} daemon is running" >> /var/log/cabal/services_checker.log
			fi
		fi
	else
		if [[ $DEBUG -eq 1 ]]; then
			echo "[$DT]: ${daemon} daemon is stopped" >> /var/log/cabal/services_checker.log
		fi
	fi
done

echo "checker_status=1" > /etc/cabal_etc/services_checker_status
/bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'
