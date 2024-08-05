#!/bin/bash

TMPDIR=`mktemp -d`
cabal_data_dir='/home/Cabal-Online-Docker/source/cabal-data'
server_data_dir='/home/Cabal-Online-Docker/source/cabal-scripts'
installator_dir='/home/Cabal-Online-Docker/installator'

/bin/bash -c "rm -f $installator_dir/cabal_default_backup.tar.gz"

cd $cabal_data_dir
tar --exclude="logs" -czf $TMPDIR/cabal_main_backup.tar.gz *
cd $server_data_dir
tar -czf $TMPDIR/_server_data.tar.gz *
cd $TMPDIR
tar -czf $installator_dir/cabal_default_backup.tar.gz *

/bin/bash -c "rm -rf $TMPDIR"
sync; echo 1 > /proc/sys/vm/drop_caches
cd
