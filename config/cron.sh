#!/bin/bash

set -ex

THISFILE=$(readlink -f $0)
export CONFDIR="$(dirname $THISFILE)"
export MAINDIR="$(dirname $CONFDIR)"

# clear log for publishing
echo "" > "$HOME/ppa-daily-publish.log"

run() {
  bash "$HOME/ppa-script/ppa-script.sh" 2>&1 | tee -a "$HOME/ppa-daily.log" | tee -a "$HOME/ppa-daily-publish.log"
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
mv "$HOME/ppa-daily-publish.log" "update.log"

# upload to ipfs and publish
HASH=$(/usr/local/bin/ipfs add -Qr "$MAINDIR")
ipfs-dnslink-update cf deb.mkg20001.io "/ipfs/$HASH"
