#!/bin/sh

set -ex

scripts/echcli.sh -H defo.ie -f ech-check.php

mkdir lt || true
cd lt
../scripts/make-example-ca.sh
openssl ech -public_name example.com || true

../scripts/echsvr.sh & ECHSVR=$!
../scripts/echcli.sh -s localhost -H foo.example.com -p 8443 -P echconfig.pem -f index.html
kill $ECHSVR

../scripts/echsvr.sh -d -e &
../scripts/echcli.sh -H foo.example.com -p 8443 -s localhost -P echconfig.pem -S ed.sess
ls -l ed.sess
../scripts/echcli.sh -H foo.example.com -p 8443 -s localhost -P echconfig.pem -S ed.sess -e
rm ed.sess
