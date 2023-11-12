#!/bin/bash
chport=$1
/usr/sbin/iptables -C DOCKER-USER --match string --algo kmp --hex-string '|E2 B7 0E 00 00 00 00 00|' -p tcp --dport $chport --jump DROP 1>> /dev/null 2>> /dev/null
if [[ $? -eq 1 ]]
then /usr/sbin/iptables -I DOCKER-USER --match string --algo kmp --hex-string '|E2 B7 0E 00 00 00 00 00|' -p tcp --dport $chport --jump DROP
fi
# iptables -D DOCKER-USER --match string --algo kmp --hex-string '|E2 B7 0E 00 00 00 00 00|' -p tcp --dport 37011 --jump DROP
