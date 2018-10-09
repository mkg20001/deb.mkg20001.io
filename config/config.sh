#!/bin/bash

OUT="$PWD/ubuntu"
KEY="A35AD290"

add_from_repo() {
  REPO="$1"
  DIST="$2"
  PKG="$3"

  pkgInRepo=$(curl --silent "$REPO/dists/$DIST/binary-amd64/Packages" | grep "$PKG/" | sed "s|.*pool|$REPO/pool|g")
  log "repo->$PKG: Updating from $REPO"
  for arch in $ARCHS; do
    pkgInRepo=$(curl --silent "$REPO/dists/$DIST/binary-$arch/Packages" | grep "$PKG/" | sed "s|.*pool|$REPO/pool|g")
    if [ -z "$pkgInRepo" ]; then
      log "repo->$PKG->$arch: Did not find anything for binary-$arch"
    else
      log "repo-$PKG->$arch: Latest is $pkgInRepo"
      add_url_auto "$PKG" "$pkgInRepo" "" "" "$arch"
    fi
  done
}

# Init Repo
_init

# Configure Repo
PPA_ARCHS="amd64 arm64 armhf i386 ppc64el"
for distro in xenial bionic cosmic; do
  add_dist "$distro" "DEB-MKG-$distro" "mkgs Update Server"
  add_comp "$distro" main
  for a in $PPA_ARCHS; do
    add_arch "$distro" "$a"
  done
done

# Anydesk
for anydesk in $(curl -s https://anydesk.de/download?os=linux | grep '.deb"' | grep -o "https.*.deb"); do
  add_url_auto anydesk "$anydesk"
done

# Zoom
for arch in amd64 i386; do
  zoom=$(curl -sI https://zoom.us/client/latest/zoom_$arch.deb | grep "^Location: " | grep -o "https.*.deb")
  add_url_auto zoom "$zoom"
done

# Duniter
for type in desktop server; do
  url=$(curl --silent https://git.duniter.org/nodes/typescript/duniter/wikis/Releases | grep -o "https://git[a-z0-9/.-]*deb" | sort -r | grep "$type" | head -n 1)
  add_url_auto "duniter_$type" "$url"
done

# Openbazaar
for openb in $(curl -s https://openbazaar.org/download/ | grep -o "https://.*\.deb"); do
  add_url_auto openbazaar "$openb"
done

# Vagrant
for vagrant in $(curl -s https://www.vagrantup.com/downloads.html | grep -o "https.*deb"); do
  add_url_auto vagrant "$vagrant"
done

# Stub (these pkgs will add own repo after install)
## Chrome
add_from_repo "https://dl.google.com/linux/chrome/deb" "stable/main" "google-chrome-stable"
## Keybase
add_from_repo "https://prerelease.keybase.io/deb" "stable/main" "keybase"

# IDE
add_gh_pkg atom atom/atom

# P2P
add_gh_pkg lbry lbryio/lbry-desktop "" "" "amd64"
add_gh_pkg webtorrent webtorrent/webtorrent-desktop
add_gh_pkg ipfs-desktop ipfs-shipyard/ipfs-desktop
add_gh_pkg pathephone pathephone/pathephone-desktop
add_gh_pkg_any tribler tribler/tribler
add_gh_pkg orion siderus/orion
add_gh_pkg bisq bisq-network/bisq

# Cloud
add_gh_pkg minikube kubernetes/minikube "" "" "amd64"

# Social media
add_gh_pkg akasha AkashaProject/Community
add_gh_pkg talenet talenet/talenet

# Other
add_url multimc "$(curl -s https://multimc.org/ | grep -o "https://files.*deb")" all
add_url pick "http://ppa.launchpad.net/sil/pick/ubuntu/pool/main/p/pick-colour-picker/pick-colour-picker_1.5-0~201702011054~ubuntu16.04.1_all.deb" all
add_gh_pkg lanshare abdularis/lan-share

# Self-compiled stuff
for url in $(curl -s https://i.mkg20001.io/deb/ | grep -o './.*deb\"' | sed "s|./|https://i.mkg20001.io/deb/|g" | sed 's|"||g'); do
  add_url_auto "$(echo $url | sed -r "s|.*deb/([a-z0-9.-]+)_.*|\1|g")" "$url"
done

# small-cleanup-script
for a in $PPA_ARCHS; do
  add_url_auto small-cleanup-script "http://ppa.launchpad.net/mkg20001/stable/ubuntu/pool/main/s/small-cleanup-script/small-cleanup-script_1.5.0-41~stable~ubuntu16.04.1_$a.deb"
done

# And... release

fin
