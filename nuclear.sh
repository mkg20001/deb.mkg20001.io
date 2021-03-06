#!/bin/bash

PKGS=()

prepare_pkgs() {
  if [ ! -e /usr/lib/apt/methods/https ]; then
    PKGS+=(apt-transport-https)
  fi

  if [ ! -x /usr/bin/curl ] && [ ! -x /usr/bin/wget ]; then
    PKGS+=(curl)
  fi

  if [ ! -z "${PKGS[*]}" ]; then
    echo "Installing ${PKGS[*]}..."
    sudo apt install -y "${PKGS[@]}"
  fi

  if [ -x /usr/bin/curl ]; then
    DLCMD=(curl -s)
  elif [ -x /usr/bin/wget ]; then
    DLCMD=(wget -qO-)
  else
    echo "ERROR: Neither wget nor curl was found..." 2>&1 && exit 2
  fi
}

add_key() {
  if LC_ALL=C apt-key list 2>/dev/null | grep "deb.mkg20001.io Repo Signing Key" > /dev/null && ! LC_ALL=C apt-key list 2>/dev/null | grep "deb.mkg20001.io Repo Signing Key" | grep expired > /dev/null; then
    echo "Skip adding key, already added"
  else
    echo -n "Adding deb.mkg20001.io key... "
    "${DLCMD[@]}" https://deb.mkg20001.io/key.asc | sudo apt-key add -
  fi
}

check_alt() {
  if [ "X${DISTRO}" == "X${2}" ]; then
    echo "Detected ${1} ${2}"
    echo "Installing repo for ${3} ${4}"
    REPO_DIST="$4"
  fi
}

add_repo() {
  repostr="deb $REPO_ROOT $REPO_DIST $REPO_CHANNEL"
  repofile="/etc/apt/sources.list.d/$LIST_FILE.list"
  if [ ! -e "$repofile" ] || [ "$(cat "$repofile")" != "$repostr" ]; then
    echo -n "Adding repo: "
    echo "$repostr" | sudo tee "$repofile"
  else
    echo "Skip adding repo, already added"
  fi
}

setup() {
  add_key
  add_repo
}


if [ -z "$REPO_CHANNEL" ]; then
  REPO_CHANNEL="beta"
fi

if [ -z "nuclear" ] && [ -z "$REPO_DIST" ]; then
  if [ ! -x /usr/bin/lsb_release ]; then
    PKGS+=(lsb-release)
  fi

  prepare_pkgs

  DISTRO=$(lsb_release -c -s)
  REPO_DIST="$DISTRO"
  do_check_alt
elif [ -z "$REPO_DIST" ]; then
  REPO_DIST="nuclear"
  prepare_pkgs
else
  prepare_pkgs
fi

REPO_BASE="nuclear"
LIST_FILE="nuclear"

if [ ! -z "$USE_IPFS" ]; then
  if [ -z "$IPFS_GATEWAY" ]; then
    IPFS_GATEWAY="http://localhost:8080"
  fi
  echo "Using IPFS repo with gateway $IPFS_GATEWAY"
  REPO_ROOT="$IPFS_GATEWAY/ipns/deb.mkg20001.io/$REPO_BASE"
elif [ ! -z "$REPO_ROOT" ]; then
  echo "Using custom repo with URL $REPO_ROOT"
  REPO_ROOT="$REPO_ROOT/$REPO_BASE"
else
  REPO_ROOT="https://deb.mkg20001.io/$REPO_BASE"
fi
setup
