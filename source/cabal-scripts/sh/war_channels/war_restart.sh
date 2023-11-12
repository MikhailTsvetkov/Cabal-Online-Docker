#!/bin/bash

/usr/bin/war_stop $1 $2 $3
sleep 3
/usr/bin/war_start $1 $2 $3
