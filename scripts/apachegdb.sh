#!/bin/bash

# set -x

# Fire up gdb with LD_LIBRARY_PATH setup for apache
# If you're following the setup I used then this
# should help if you wanna use gdb for apache

# where our builds are...
CODETOP=$HOME/code/openssl
AP_TOP=$HOME/code/httpd
RUNTOP=$HOME/lt

# name of apache config we're using - used to decide what processes to
# kill off before starting gdb, and when starting gdb as well
AP_CFGNAME=$HOME/ech-dev-utils/configs/apachemin.conf

OSSL_LP=$CODETOP
HTTPD_LP=$AP_TOP/.libs
APR_LP=$AP_TOP/srclib/apr/.libs
MO_LP=$AP_TOP/modules/ssl/.libs
AAA_LP=$AP_TOP/modules/aaa/.libs
ENV_LP=$AP_TOP/modules/metadata/.libs/
CFG_LP=$AP_TOP/modules/loggers/.libs/
UNIX_LP=$AP_TOP/modules/arch/unix/.libs/

export LD_LIBRARY_PATH="$OSSL_LP:$HTTPD_LP:$APR_LP:$MO_LP:$ENV_LP:$CFG_LP:$UNIX_LP"

# kill off other processes
procs=`ps -ef | grep httpd | grep $AP_CFGNAME | grep -v grep | awk '{print $2}'`
for proc in $procs
do
    echo "Killing $proc"
    kill -9 $proc
done
sleep 2

# go to the right place and fire up gdb, as needed
cd $RUNTOP
# we take one argument that can be a breakpoint
if [[ "$1" != "" ]]
then
    echo "Setting breakpoint to $1"
    gdb -ex "set breakpoint pending on" -ex "b \"$1\"" -exec $AP_TOP/.libs/httpd -ex "run -X -d . -f $AP_CFGNAME -DFOREGROUND" 
else
    gdb -exec $AP_TOP/.libs/httpd -ex "run -X -d . -f $AP_CFGNAME -DFOREGROUND" 
fi


