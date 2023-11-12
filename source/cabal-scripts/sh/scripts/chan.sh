#!/bin/bash
source /home/_server_data/sh/scripts/functions.sh

# chan 1 main start|stop|restart|reload -dt|server_num -dt

get_server_num $4
if [[ $snum -eq 0 ]]; then
	snum="01"
fi

if [[ $4 == '-dt' || $5 == '-dt' ]]; then
	dt='-dt'
fi

check_container_exists $2 $dt
if [[ $? -eq 1 ]]; then
	exit 0
fi
check_container_running cabal $2 $dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

find /home/data_${2}/cabal_bin -type f -print0 | xargs -0 -r -n 100 -P 6 chmod 0700

if [[ $1 -gt 9 ]] ; then
	chnum=$1
else
	chnum=0$1
fi

daemon=WorldSvr_${snum}_${chnum}
chan_type=$(sed '/\[Server${snum}\]/,/\[/p' /home/data_${2}/cabal/GlobalMgrSvr.ini | grep "ChannelType${chnum}=[0-9]*" | grep -vm1 "#" | grep -oP '=\K.*')
chan_type=${chan_type//[^0-9]}

case $3 in

	start)
		chport=`grep -m1 -w "Port" /home/data_${2}/cabal/${daemon}.ini | cut -d "=" -f 2`
		/usr/bin/anticrash $chport
		cabal_service start $2 $daemon $dt
		if [[ $chan_type -lt 10000000 ]] && [[ $chan_type -ne 32 ]]; then
			echo 1 > /home/data_${2}/cabal_scripts/services_checker/$daemon
		fi
		;;

	stop)
		if [[ $chan_type -lt 10000000 ]] && [[ $chan_type -ne 32 ]]; then
			echo 0 > /home/data_${2}/cabal_scripts/services_checker/$daemon
		fi
		cabal_service stop $2 $daemon $dt
		;;

	restart)
		chport=`grep -m1 -w "Port" /home/data_${2}/cabal/${daemon}.ini | cut -d "=" -f 2`
		/usr/bin/anticrash $chport
		if [[ $chan_type -lt 10000000 ]] && [[ $chan_type -ne 32 ]]; then
			echo 0 > /home/data_${2}/cabal_scripts/services_checker/$daemon
		fi
		cabal_service restart $2 $daemon $dt
		if [[ $chan_type -lt 10000000 ]] && [[ $chan_type -ne 32 ]]; then
			echo 1 > /home/data_${2}/cabal_scripts/services_checker/$daemon
		fi
		;;

	reload)
		cabal_service reload $2 $daemon $dt
		;;

	status)
		docker exec cabal_$2 /bin/bash -c "/etc/cabal_scripts/status.sh $daemon"
		;;
	
	*)
		if [[ ! $dt == '-dt' ]]; then
			echo -e "\n${RED}An argument must be added to the command.${NC}"
			echo -e "${YELLOW}Supported arguments:${NC}"
			echo -e "start"
			echo -e "stop"
			echo -e "restart"
			echo -e "reload"
			echo -e "status"
			echo -e "${BLUE}For example ${PINK}chan 16 main restart${NC}"
			echo
		fi
		exit 0
		;;
esac

docker exec cabal_${2} /bin/bash -c 'rm -f /etc/cabal_etc/core/* && rm -f /core.*'
