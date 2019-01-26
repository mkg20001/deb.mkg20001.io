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
  echo -n "Adding deb.mkg20001.io key... "
  "${DLCMD[@]}" https://deb.mkg20001.io/key.asc | sudo apt-key add -
}

check_alt() {
  if [ "X${DISTRO}" == "X${2}" ]; then
    echo "Detected ${1} ${2}"
    echo "Installing repo for ${3} ${4}"
    REPO_DIST="$4"
  fi
}

add_repo() {
  echo -n "Adding repo: "
  echo "deb $REPO_ROOT $REPO_DIST $REPO_CHANNEL" | sudo tee /etc/apt/sources.list.d/mkg.list
}

setup() {
  add_key
  add_repo
}
#!/bin/bash

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
