#!/bin/bash

channels_stop $1 $2 $3
sleep 3
channels_start $1 $2 $3
