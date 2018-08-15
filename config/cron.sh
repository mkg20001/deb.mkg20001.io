#!/bin/bash

set -ex

THISFILE=$(readlink -f $0)
CONFDIR="$(dirname $THISFILE)"
MAINDIR="$(dirname $CONFDIR)"

run() {
  bash "$HOME/ppa-script/ppa-script.sh" 2>&1 | tee -a "$HOME/ppa-daily.log"
}

# pull latest ppa-script
cd "$HOME/ppa-script"
git pull

# self-update & run
cd "$MAINDIR"
git pull
CONFIG="$CONFDIR/config.sh" run

# upload to ipfs and publish
ipfs-dnslink-update cf deb.mkg20001.io "/ipfs/$(/usr/local/bin/ipfs add -Qr $MAINDIR)"
