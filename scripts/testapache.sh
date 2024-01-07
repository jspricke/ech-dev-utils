#!/bin/bash

# set -x

set -e

# to pick up correct executables and .so's
EDTOP="$(dirname "$(realpath "$0")")/.."
# where we have/want test files
RUNTOP=$(mktemp -d)

. $EDTOP/scripts/funcs.sh

CLILOGFILE=`mktemp`
SRVLOGFILE=`mktemp`
KEEPLOG="no"

allgood="yes"

prep_server_dirs apache

mkdir -p "$RUNTOP/echkeydir"
cd "$RUNTOP"

mkdir -p apache/logs

"$EDTOP/scripts/make-example-ca.sh"
openssl ech -public_name example.com -pemout echkeydir/echconfig.pem.ech || true
ln -s echkeydir/echconfig.pem.ech echconfig.pem
sed "s#\$RUNTOP#$RUNTOP#g" "$EDTOP/configs/apachemin.conf" > "$RUNTOP/apache/apachemin.conf"

# if we want to reload config then that's "graceful restart"
if [[ "$1" == "graceful" ]]
then
    echo "Telling apache to do the graceful thing"
    apache2 -d "$RUNTOP" -f "$RUNTOP/apache/apachemin.conf" -k graceful
    exit $?
fi

echo "Executing: apache2 -d $RUNTOP -f $RUNTOP/apache/apachemin.conf"
apache2 -d "$RUNTOP" -f "$RUNTOP/apache/apachemin.conf"

for type in grease public real hrr
do
    port=9443
    echo "Testing $type $port"
    cli_test $port $type
done

PIDFILE="$RUNTOP/apache/logs/httpd.pid"
if [ -f "$PIDFILE" ]
then
    echo "Killing httpd in process $(cat "$PIDFILE")"
    kill "$(cat "$PIDFILE")"
    rm -f "$PIDFILE"
fi
