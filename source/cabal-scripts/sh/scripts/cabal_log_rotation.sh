#!/bin/bash

check_container_exists $1 -dt
if [[ $? -eq 1 ]]; then
	exit 0
fi

maxsize=$(($2*1024*1024))
path="/home/data_${1}/logs"
files=`ls $path/*.log | rev | cut -d'/' -f1 | rev | xargs -n 1 -i echo "{}"`
rdir=$path/log_rotation

for file in $files
do
	logfile=$path/$file
	size=$(wc -c <"$logfile")
	if [[ $size -ge $maxsize ]]; then
		if ! [ -d $path/log_rotation ]; then
			mkdir -p $path/log_rotation
		fi
		if [ -f "${rdir}/${file}.3" ]; then
			rm -f "${rdir}/${file}.3"
		fi
		if [ -f "${rdir}/${file}.2" ]; then
			mv -f "${rdir}/${file}.2" "${rdir}/${file}.3"
		fi
		if [ -f "${rdir}/${file}.1" ]; then
			mv -f "${rdir}/${file}.1" "${rdir}/${file}.2"
		fi
		cp $logfile "${rdir}/${file}.1"
		cp /dev/null $logfile
	fi
done
