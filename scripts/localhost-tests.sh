#!/bin/bash

# set -e
set -ex

# A couple of basic openssl ECH tests

# Override-able paths
: ${EDTOP:="$HOME/code/ech-dev-utils"}
: ${CODETOP:=$HOME/code/openssl}
if [[ "$PACKAGING" == "" ]]
then
    export LD_LIBRARY_PATH=$CODETOP
    CMDPATH=$CODETOP/apps/openssl
else
    CMDPATH=`which openssl`
    EDTOP="."
fi

# we assume we're in the root of a checked out ech-dev-utils repo

# basic ECH check vs. defo.ie
$EDTOP/scripts/echcli.sh -d -H defo.ie -f ech-check.php

# mkdir -p lt || true
# cd lt

if [ ! -d cadir ]
then
    # debugging;-(
    echo "$EDTOP"
    ls $EDTOP/scripts
    # don't re-do this if not needed, might break other configs
    $EDTOP/scripts/make-example-ca.sh
fi
if [ ! -f echconfig.pem ]
then
    $CMDPATH ech -public_name example.com || true
fi

$EDTOP/scripts/echsvr.sh & ECHSVR=$!
$EDTOP/scripts/echcli.sh -s localhost -H foo.example.com -p 8443 -P echconfig.pem -f index.html

$EDTOP/scripts/echcli.sh -H foo.example.com -p 8443 -s localhost -P echconfig.pem -S ed.sess
ls -l ed.sess
$EDTOP/scripts/echcli.sh -H foo.example.com -p 8443 -s localhost -P echconfig.pem -S ed.sess -e
rm ed.sess
kill $ECHSVR


