#!/bin/bash

# set -x

set -e

# to pick up correct executables and .so's
EDTOP="$(dirname "$(realpath "$0")")/.."
export EDTOP
# where we have/want test files
RUNTOP=$(mktemp -d)
export RUNTOP
chmod a+rx "$RUNTOP"

# make directories for nginx stuff if needed
mkdir -p $RUNTOP/nginx/logs
mkdir -p $RUNTOP/nginx/www
mkdir -p $RUNTOP/nginx/foo
mkdir -p "$RUNTOP/echkeydir"

# in case we wanna dump core and get a backtrace, make a place for
# that (dir name is also in configs/nginxmin.conf)
mkdir -p /tmp/cores

allgood="yes"

function whenisitagain()
{
    /bin/date -u +%Y%m%d-%H%M%S
}
NOW=$(whenisitagain)

CLILOGFILE=`mktemp`
SRVLOGFILE=`mktemp`
KEEPLOG="no"
EARLY="yes"
SPLIT="no"

. $EDTOP/scripts/funcs.sh

prep_server_dirs nginx

# set to use valgrind, unset to not
# VALGRIND="valgrind --leak-check=full --show-leak-kinds=all"
VALGRIND=""

# Set/unset to detach or run in foreground
FGROUND=""
# FGROUND="-DFOREGROUND "

# if we don't have a local config, replace pathnames in repo version
# and copy to where it's needed
if [ ! -f $RUNTOP/nginx/nginxmin.conf ]
then
    do_envsubst
fi
# if the repo version of the config is newer, then backup the RUNTOP
# version and re-run envsubst
repo_date=`stat -c %Y $EDTOP/configs/nginxmin.conf`
runtop_date=`stat -c %Y $RUNTOP/nginx/nginxmin.conf`
if (( repo_date >= runtop_date))
then
    cp $RUNTOP/nginx/nginxmin.conf $RUNTOP/nginx/nginxmin.conf.$NOW
    do_envsubst
fi

echo "Executing: $VALGRIND nginx -c nginxmin.conf"
# move over there to run code, so config file can have relative paths
cd $RUNTOP
"$EDTOP/scripts/make-example-ca.sh"
openssl ech -public_name example.com -pemout echkeydir/echconfig.pem.ech || true
ln -s echkeydir/echconfig.pem.ech echconfig.pem
$VALGRIND nginx -c "$RUNTOP/nginx/nginxmin.conf"

trap "nginx -s quit" EXIT INT QUIT PIPE

for type in grease public real hrr
do
    port=5443
    echo "Testing $type $port"
    cli_test $port $type
done

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
