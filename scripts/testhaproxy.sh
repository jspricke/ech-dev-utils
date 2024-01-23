#!/bin/bash

# set -x
set -e

# Run a haproxy test

EDTOP="$(dirname "$(realpath "$0")")/.."
export EDTOP
RUNTOP=$(mktemp -d)
export RUNTOP

HLOGDIR="$RUNTOP/haproxy/logs"
SRVLOGFILE="$HLOGDIR/haproxy.log"
CLILOGFILE="$HLOGDIR/clienttest.log"
BE_PIDFILE="$RUNTOP/haproxy/logs/haproxy.pid"
KEEPLOG="no"

allgood="yes"

. $EDTOP/scripts/funcs.sh

mkdir -p "$RUNTOP/echkeydir"
mkdir -p "$RUNTOP/lighttpd/logs"
mkdir -p "$RUNTOP/lighttpd/dir-example.com"
cd "$RUNTOP"

"$EDTOP/scripts/make-example-ca.sh"
openssl ech -public_name example.com -pemout echkeydir/echconfig.pem.ech || true
ln -s echkeydir/echconfig.pem.ech echconfig.pem

prep_server_dirs lighttpd

mkdir -p $HLOGDIR

if [ ! -f $SRVLOGFILE ]
then
    touch $SRVLOGFILE
    chmod a+w $SRVLOGFILE
fi

lighty_start $EDTOP/configs/lighttpd4haproxymin.conf

# Now start up a haproxy
# run haproxy in background
HAPDEBUGSTR=" -DdV " 
echo "Executing: haproxy -f $EDTOP/configs/haproxymin.conf $HAPDEBUGSTR >$SRVLOGFILE 2>&1"
haproxy -f $EDTOP/configs/haproxymin.conf $HAPDEBUGSTR >$SRVLOGFILE 2>&1

# all things should appear the same to the client
# server log checks will tells us if stuff worked or not
echo "Doing shared-mode client calls..."
for type in grease public real hrr
do
    for port in 7443 7444 7445
    do
        echo "Testing $type $port"
        cli_test $port $type
    done
done

lighty_stop
kill "$(cat "$BE_PIDFILE")"

rm -f $BE_PIDFILE

if [[ "$allgood" == "yes" ]]
then
    echo "All good."
    rm -f $CLILOGFILE $SRVLOGFILE
else
    echo "Something failed."
    if [[ "$KEEPLOG" != "no" ]]
    then
        echo "Client logs in $CLILOGFILE"
        echo "Server logs in $SRVLOGFILE"
    else
        rm -f $CLILOGFILE $SRVLOGFILE
    fi
fi

