#!/bin/bash

# Run a lighttpd on localhost:3443 with foo.example.com accessible
# via ECH

set -x
set -e

EDTOP="$(dirname "$(realpath "$0")")/.."
export EDTOP
RUNTOP=$(mktemp -d)
export RUNTOP

PIDFILE=$RUNTOP/lighttpd/logs/lighttpd.pid
CLILOGFILE=`mktemp`
SRVLOGFILE=`mktemp`
KEEPLOG="no"

allgood="yes"

. "$EDTOP/scripts/funcs.sh"

mkdir -p "$RUNTOP/echkeydir"
mkdir -p "$RUNTOP/lighttpd/logs"
mkdir -p "$RUNTOP/lighttpd/dir-example.com"
cd "$RUNTOP"

"$EDTOP/scripts/make-example-ca.sh"
openssl ech -public_name example.com -pemout echkeydir/echconfig.pem.ech || true
ln -s echkeydir/echconfig.pem.ech echconfig.pem

prep_server_dirs lighttpd

lighty_start $EDTOP/configs/lighttpdmin.conf

for type in grease public real hrr
do
    port=3443
    echo "Testing $type $port"
    cli_test $port $type
done

lighty_stop

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

