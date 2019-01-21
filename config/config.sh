#!/bin/bash

OUT="$PWD/ubuntu"
KEY="A35AD290"

. "$CONFDIR/_functions.sh"

# Init Repo
_init

# Configure Repo
PPA_ARCHS="amd64 arm64 armhf i386 ppc64el"
PPA_DISTS="xenial bionic cosmic disco"
for distro in $PPA_DISTS; do
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

# Packer (zip2deb)

# TODO: factor into own function
PACKER_ZIP=$(curl -s https://www.packer.io/downloads.html | grep linux_amd64 | grep -o "https.*\\.zip")

if [ "$(_db_w packer packer_zip)" != "$PACKER_ZIP" ]; then
  log "zip2deb->packer: Generating from $PACKER_ZIP"
  _tmp_init

  wget "$PACKER_ZIP" -O "packer.zip"
  unzip "packer.zip"
  chmod 755 packer
  mkdir -p usr/local/bin
  mv packer usr/local/bin
  Z2D_OUT=$(basename "$PACKER_ZIP")
  Z2D_OUT=${Z2D_OUT/".zip"/".tar.gz"}
  tar cvfz "$Z2D_OUT" usr
  fakeroot alien -d --target=amd64 --fixperms "$Z2D_OUT"
  DEB=$(ls | grep ".deb$")

  log "zip2deb->packer: Generated!"
  _db_w packer packer_zip "$PACKER_ZIP"

  OLD_DEB=$(_db_r packer packer_file)
  if [ ! -z "$OLD_DEB" ]; then
    rm_pkg_file "$OLD_DEB"
  fi
  add_pkg_file "$DEB"

  _db_w packer packer_file "$DEB"
  _tmp_exit
fi

# Siderus Orion
ORION_VERSION=$(curl "https://get.siderus.io/orion/latest-version")
ORION="https://get.siderus.io/orion/orion_${ORION_VERSION}_amd64.deb"
add_url_auto orion "$ORION"

# Stub (these pkgs will add own repo after install)
## Chrome
add_from_repo "https://dl.google.com/linux/chrome/deb" "stable" "main" "google-chrome-stable"
## Keybase
add_from_repo "https://prerelease.keybase.io/deb" "stable" "main" "keybase"
## Syncthing
add_from_repo "https://apt.syncthing.net" "syncthing" "stable" "syncthing"

# Clone (repos that I just cloned)
# TODO: full clone
## Gamehub
add_from_repo "http://ppa.launchpad.net/tkashkin/gamehub/ubuntu" "" "main" "com.github.tkashkin.gamehub"
## Node v10
add_from_repo "https://deb.nodesource.com/node_10.x" "" "main" "nodejs"
# small-cleanup-script
add_from_repo "http://ppa.launchpad.net/mkg20001/stable/ubuntu" "" "main" "small-cleanup-script"
# color picker
add_from_repo "http://ppa.launchpad.net/sil/pick/ubuntu" "" "main" "pick-colour-picker"
# virtualbox
add_from_repo "https://download.virtualbox.org/virtualbox/debian" "" "contrib" "virtualbox-5.2"
# x2go
# add_from_repo "http://ppa.launchpad.net/x2go/stable/ubuntu" "" "main" ""
# riot.im
add_from_repo "https://riot.im/packages/debian" "" "main" "riot-web"

# IDE
add_gh_pkg atom atom/atom

# P2P
add_gh_pkg lbry lbryio/lbry-desktop "" "" "amd64"
add_gh_pkg webtorrent webtorrent/webtorrent-desktop
add_gh_pkg ipfs-desktop ipfs-shipyard/ipfs-desktop
add_gh_pkg pathephone pathephone/pathephone-desktop
add_gh_pkg_any tribler tribler/tribler
add_gh_pkg bisq bisq-network/bisq

# Cloud
add_gh_pkg minikube kubernetes/minikube "" "" "amd64"

# Social media
add_gh_pkg akasha AkashaProject/Community
add_gh_pkg talenet talenet/talenet

# Other
add_url multimc "$(curl -s https://multimc.org/ | grep -o "https://files.*deb")" all
add_gh_pkg lanshare abdularis/lan-share
add_gh_pkg_any nuclear nukeop/nuclear

# Self-compiled stuff
for url in $(curl -s https://i.mkg20001.io/deb/ | grep -o './.*deb\"' | sed "s|./|https://i.mkg20001.io/deb/|g" | sed 's|"||g'); do
  add_url_auto "$(echo $url | sed -r "s|.*deb/([a-z0-9.-]+)_.*|\1|g")" "$url"
done

# And... release

fin
