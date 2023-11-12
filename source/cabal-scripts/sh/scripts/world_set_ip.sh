#!/bin/bash

servers=`docker ps --filter name=cabal_ --format "{{.Names}}" -a | sed 's/cabal_//'`
for srv in $servers
do
	sed -i -e "s/IPAddress=.*/IPAddress=$1/g" /home/data_${srv}/cabal/WorldSvr*
	sed -i -e "s/AddrForClient=.*/AddrForClient=$1/g" /home/data_${srv}/cabal/WorldSvr*
done
