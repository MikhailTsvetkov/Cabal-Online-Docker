#!/bin/bash

echo "checker_status=0" > /etc/cabal_etc/services_checker_status
rm -f /etc/cabal_scripts/services_checker/*
exec "/usr/bin/supervisord"
