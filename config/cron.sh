#!/bin/bash

set -ex

THISFILE=$(readlink -f $0)
export CONFDIR="$(dirname $THISFILE)"
export MAINDIR="$(dirname $CONFDIR)"

run() {
  bash "$HOME/ppa-script/ppa-script.sh" 2>&1 | tee -a "$HOME/ppa-daily.log"
}

if [ ! -z "$DEV" ]; then
  cd "$MAINDIR"
  CONFIG="$CONFDIR/config.dev.sh" run
  exit 0
fi

# pull latest ppa-script
cd "$HOME/ppa-script"
git pull

# self-update & run
cd "$MAINDIR"
git pull
CONFIG="$CONFDIR/config.sh" run
CONFIG="$CONFDIR/config.nuclear.sh" run

# upload to ipfs and publish
HASH=$(/usr/local/bin/ipfs add -Qr "$MAINDIR")
ipfs-dnslink-update cf deb.mkg20001.io "/ipfs/$HASH"
