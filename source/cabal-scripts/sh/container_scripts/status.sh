#!/bin/bash

daemons=`cat /etc/cabal_structure/server_list | grep -v ^#`
channels=`cat /etc/cabal_structure/channels_list | grep -v ^#`
war=`cat /etc/cabal_structure/war_list | grep -v ^#`

case "$1" in
  -s)
		trg=$daemons
		chk_proxy=1
		status_list=1
        ;;
  -c)
		trg=$channels
		chk_proxy=1
		status_list=1
        ;;
  -w)
		trg=$war
		chk_proxy=1
		status_list=1
        ;;
  *)
        trg=$1
		chk_proxy=0
		status_list=0
esac

NC='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'

# Check proxy
if [[ $chk_proxy -eq 1 ]]; then
	cat -T /etc/cabal_structure/proxy_list | egrep -v "(^\[|^#)" | while read ln
	do
		ln=${ln//'^I'/':'}
		ln=${ln//' '/':'}
		gmsId=`echo $ln | cut -d ":" -f1`
		gmsPort=`echo $ln | cut -d ":" -f2`
		if [[ $gmsPort != '' && $gmsPort -gt 0 && $gmsPort -le 65535 ]]; then
			if [[ $gmsId -lt 10 ]]; then
				gmsId="0${gmsId}"
			fi
			if [ -f /etc/cabal_scripts/services_checker/proxy_$gmsId ]; then
				chk=`head -n1 /etc/cabal_scripts/services_checker/proxy_$gmsId | tr -s '\n' ' '`
				if [[ $chk -eq 1 ]]; then
					ping=`nmap 127.0.0.1 -p $gmsPort | grep -q "/tcp *open " || echo 1`
					if [[ $ping -eq 1 ]]; then
						echo -e "${RED} • gms_proxy_$gmsId [$gmsPort] is crashed${NC}"
					else
						echo -e "${GREEN} • gms_proxy_$gmsId [$gmsPort] is running${NC}"
					fi
				else
					echo -e " • gms_proxy_$gmsId [$gmsPort] is stopped"
				fi
			else
				echo -e " • gms_proxy_$gmsId [$gmsPort] is stopped"
			fi
		fi
	done
fi

# Check Cabal services
if [[ $status_list -eq 1 ]]; then
	for daemon in $trg
	do
		if [ -f /etc/cabal_scripts/services_checker/$daemon ]; then
			chk=`head -n1 /etc/cabal_scripts/services_checker/$daemon | tr -s '\n' ' '`
			if [[ $chk -eq 1 ]]; then
				port=`grep -m1 -w "Port" /etc/cabal/${daemon}.ini | cut -d "=" -f 2`
				ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
				if [[ $ping -eq 1 ]]; then
					echo -e "${RED} • ${daemon} is crashed${NC}"
				else
					echo -e "${GREEN} • ${daemon} is running${NC}"
				fi
			else
				echo -e " • ${daemon} is stopped"
			fi
		else
			port=`grep -m1 -w "Port" /etc/cabal/${daemon}.ini | cut -d "=" -f 2`
			ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
			if [[ $ping -eq 1 ]]; then
				echo -e " • ${daemon} is stopped"
			else
				echo -e "${GREEN} • ${daemon} is running${NC}"
			fi
			
		fi
	done
	
# Check Daemon
else
	daemon=$trg
	if [ -f /etc/cabal_scripts/services_checker/$daemon ]; then
		chk=`head -n1 /etc/cabal_scripts/services_checker/$daemon | tr -s '\n' ' '`
		if [[ $chk -eq 1 ]]; then
			port=`grep -m1 -w "Port" /etc/cabal/${daemon}.ini | cut -d "=" -f 2`
			ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
			if [[ $ping -eq 1 ]]; then
				echo -e "${RED} • ${daemon} is crashed${NC}"
			else
				echo -e "${GREEN} • ${daemon} is running${NC}"
			fi
		else
			echo -e " • ${daemon} is stopped"
		fi
	else
		port=`grep -m1 -w "Port" /etc/cabal/${daemon}.ini | cut -d "=" -f 2`
		ping=`nmap 127.0.0.1 -p $port | grep -q "/tcp *open " || echo 1`
		if [[ $ping -eq 1 ]]; then
			echo -e " • ${daemon} is stopped"
		else
			echo -e "${GREEN} • ${daemon} is running${NC}"
		fi
		
	fi
fi
