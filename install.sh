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

do_check_alt() {
  check_alt "SolydXK"       "solydxk-9" "Debian" "stretch"
  check_alt "Kali"          "sana"     "Debian" "jessie"
  check_alt "Kali"          "kali-rolling" "Debian" "jessie"
  check_alt "Sparky Linux"  "Nibiru"   "Debian" "buster"
  check_alt "MX Linux 17"   "Horizon"  "Debian" "stretch"
  check_alt "Linux Mint"    "maya"     "Ubuntu" "precise"
  check_alt "Linux Mint"    "qiana"    "Ubuntu" "trusty"
  check_alt "Linux Mint"    "rafaela"  "Ubuntu" "trusty"
  check_alt "Linux Mint"    "rebecca"  "Ubuntu" "trusty"
  check_alt "Linux Mint"    "rosa"     "Ubuntu" "trusty"
  check_alt "Linux Mint"    "sarah"    "Ubuntu" "xenial"
  check_alt "Linux Mint"    "serena"   "Ubuntu" "xenial"
  check_alt "Linux Mint"    "sonya"    "Ubuntu" "xenial"
  check_alt "Linux Mint"    "sylvia"   "Ubuntu" "xenial"
  check_alt "Linux Mint"    "tara"     "Ubuntu" "bionic"
  check_alt "Linux Mint"    "tessa"    "Ubuntu" "bionic"
  check_alt "LMDE"          "betsy"    "Debian" "jessie"
  check_alt "LMDE"          "cindy"    "Debian" "stretch"
  check_alt "elementaryOS"  "luna"     "Ubuntu" "precise"
  check_alt "elementaryOS"  "freya"    "Ubuntu" "trusty"
  check_alt "elementaryOS"  "loki"     "Ubuntu" "xenial"
  check_alt "elementaryOS"  "juno"     "Ubuntu" "bionic"
  check_alt "Trisquel"      "toutatis" "Ubuntu" "precise"
  check_alt "Trisquel"      "belenos"  "Ubuntu" "trusty"
  check_alt "Trisquel"      "flidas"   "Ubuntu" "xenial"
  check_alt "Uruk GNU/Linux" "lugalbanda" "Ubuntu" "xenial"
  check_alt "BOSS"          "anokha"   "Debian" "wheezy"
  check_alt "BOSS"          "anoop"   "Debian" "jessie"
  check_alt "bunsenlabs"    "bunsen-hydrogen" "Debian" "jessie"
  check_alt "bunsenlabs"    "helium"   "Debian" "stretch"
  check_alt "Tanglu"        "chromodoris" "Debian" "jessie"
  check_alt "PureOS"        "green"    "Debian" "sid"
  check_alt "Devuan"        "jessie"   "Debian" "jessie"
  check_alt "Devuan"        "ascii"    "Debian" "stretch"
  check_alt "Devuan"        "ceres"    "Debian" "sid"
  check_alt "Deepin"        "panda"    "Debian" "sid"
  check_alt "Deepin"        "unstable" "Debian" "sid"
  check_alt "Pardus"        "onyedi"   "Debian" "stretch"
  check_alt "Liquid Lemur"  "lemur-3"  "Debian" "stretch"
  check_alt "Continuum"     "mx-linux" "Debian" "stretch"
}



if [ -z "$REPO_CHANNEL" ]; then
  REPO_CHANNEL="main"
fi

if [ -z "" ] && [ -z "$REPO_DIST" ]; then
  if [ ! -x /usr/bin/lsb_release ]; then
    PKGS+=(lsb-release)
  fi

  prepare_pkgs

  DISTRO=$(lsb_release -c -s)
  REPO_DIST="$DISTRO"
  do_check_alt
elif [ -z "$REPO_DIST" ]; then
  REPO_DIST=""
  prepare_pkgs
else
  prepare_pkgs
fi

REPO_BASE="ubuntu"
LIST_FILE="mkg"

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
