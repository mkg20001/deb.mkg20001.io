#!/bin/bash

OUT="$PWD/ubuntu"
KEY="A35AD290"

. "$CONFDIR/_functions.sh"

# Init Repo
_init

# Configure Repo
PPA_ARCHS="amd64 arm64 armhf i386 ppc64el"
PPA_DISTS="xenial bionic focal"
for distro in $PPA_DISTS; do
  add_dist "$distro" "DEB-MKG-$distro" "mkgs Update Server"
  add_comp "$distro" main
  for a in $PPA_ARCHS; do
    add_arch "$distro" "$a"
  done
done

# Misc internal stuff
rp_init mkg-pin-repo https://mkg20001.io
if $RP_CONTINUE; then
  echo "Explanation: Prefer deb.mkg20001.io over the Ubuntu Native packages
Package: *
Pin: origin deb.mkg20001.io
Pin-Priority: 1001" > pin
  install -D pin etc/apt/preferences.d/pin-deb.mkg20001.pref
  RP_VER=1.0.0
  rp_pack etc
  rp_finish
fi

# Cloudflare
for cfd in $(curl -s https://developers.cloudflare.com/argo-tunnel/downloads/ | grep linux | grep -o "https.*.deb"); do
  add_url_auto cloudflared "$cfd"
done

# Anydesk
for anydesk in $(curl -s https://anydesk.com/de/downloads/linux?os=linux | grep '.deb' | grep -o "https:[a-z0-9._/-]*deb" | sort | uniq); do
  add_url_auto anydesk "$anydesk"
done

# yggdrasil
for ygg in $(curl -s 'https://circleci.com/api/v1.1/project/github/yggdrasil-network/yggdrasil-go/latest/artifacts?branch=master&filter=successful' | grep -o https.*.deb | grep "/yggdrasil-"); do
  add_url_auto yggdrasil "$ygg"
done

# Zoom
for arch in amd64 i386; do
  zoom=$(curl -sI https://zoom.us/client/latest/zoom_$arch.deb | grep "^[Ll]ocation: " | grep -o "https.*.deb")
  add_url_auto zoom "$zoom"
done

# Teamviewer
for arch in amd64 i386; do
  tv=$(curl -sI https://download.teamviewer.com/download/linux/teamviewer_$arch.deb | grep "^[Ll]ocation: " | grep -o "https.*.deb")
  add_url_auto tv "$tv"
done

# Duniter
for type in desktop server; do
  url=$(curl --silent https://git.duniter.org/nodes/typescript/duniter/wikis/Releases | grep -o "https://git[a-z0-9/.-]*deb" | sort -r | grep "$type" | head -n 1)
  add_url_auto "duniter_$type" "$url"
done

# Openbazaar
# for openb in $(curl -s https://openbazaar.org/download/ | grep -o "https://.*\.deb"); do
#   add_url_auto openbazaar "$openb"
# done

# Vagrant
for vagrant in $(curl -s https://www.vagrantup.com/downloads.html | grep -o "https.*deb"); do
  add_url_auto vagrant "$vagrant"
done

# Hashicorp Packer
rp_init packer "$(curl -s https://www.packer.io/downloads.html | grep linux_amd64 | grep -o "https.*\\.zip")"
if $RP_CONTINUE; then
  unzip "$RP_FILE"
  install -D packer usr/local/bin/packer
  rp_ver
  rp_pack usr
  rp_finish
fi

# Mitmproxy.org
MITM_LATEST_VER=$(curl -s 'https://s3-us-west-2.amazonaws.com/snapshots.mitmproxy.org?delimiter=/&prefix=' | grep -o "<Prefix>[0-9.]*/</Prefix>" | grep -o "[0-9.]*" | sort -r | head -n 1)
rp_init mitmproxy "https://snapshots.mitmproxy.org/$MITM_LATEST_VER/$(curl -s "https://s3-us-west-2.amazonaws.com/snapshots.mitmproxy.org?delimiter=/&prefix=$MITM_LATEST_VER/" | grep -o "<Key>[0-9.]*/[a-z0-9.-]*</Key>" | grep -o "/[a-z0-9.-]*" | grep -o "[a-z0-9.-]*" | grep linux | grep mitmproxy)"
if $RP_CONTINUE; then
  mkdir m && cd m
  tar xfz "../$RP_FILE"
  for m in mitm*; do
    install -D "$m" "usr/local/bin/$m"
  done
  rp_ver
  rp_pack usr
  rp_finish
fi

# overmind
rp_init overmind "$(gh_get_latest DarthSim/overmind | grep -o "https.*linux-amd64.gz")"
if $RP_CONTINUE; then
  gzip -d "$RP_FILE"
  mv -v overmind* overmind
  install -D overmind usr/local/bin/overmind
  rp_ver
  rp_pack usr
  rp_finish
fi

# darch
rp_init darch "$(gh_get_latest godarch/darch | grep -o "https.*-amd64.tar.gz")"
if $RP_CONTINUE; then
  tar xvfz "$RP_FILE"
  rp_ver
  rp_pack usr
  rp_finish
fi

# hivemind
rp_init hivemind "$(gh_get_latest DarthSim/hivemind | grep -o "https.*linux-amd64.gz")"
if $RP_CONTINUE; then
  gzip -d "$RP_FILE"
  mv -v hivemind* hivemind
  install -D hivemind usr/local/bin/hivemind
  rp_ver
  rp_pack usr
  rp_finish
fi

# ipfs
rp_init go-ipfs "https://dist.ipfs.io/$(curl -s https://dist.ipfs.io/ | grep go-ipfs | grep amd64 | grep linux | grep -o "go-ipfs.*.tar.gz")"
if $RP_CONTINUE; then
  tar xvfz "$RP_FILE"
  install -D go-ipfs/ipfs usr/local/bin/ipfs
  rp_ver
  rp_pack usr
  rp_finish
fi

# fs-repo-migrations
rp_init fs-repo-migrations "https://dist.ipfs.io/$(curl -s https://dist.ipfs.io/ | grep fs-repo-migrations | grep amd64 | grep linux | grep -o "fs-repo-migrations.*.tar.gz")"
if $RP_CONTINUE; then
  tar xvfz "$RP_FILE"
  install -D fs-repo-migrations/fs-repo-migrations usr/local/bin/fs-repo-migrations
  rp_ver
  rp_pack usr
  rp_finish
fi

# termshark
rp_init termshark "$(gh_get_latest gcla/termshark | grep -o "https.*linux_x64.tar.gz")"
if $RP_CONTINUE; then
  tar xvfz "$RP_FILE"
  mv -v "$(dir -w 1 | grep "^termshark" | grep "x64\$")/termshark" termshark
  install -D termshark usr/local/bin/termshark
  rp_ver
  rp_pack usr
  rp_finish
fi

# gifski

GIFSKI=$(curl https://gif.ski/ | grep -o "/[a-z0-9.-]*.zip")
GIFSKI="https://gif.ski$GIFSKI"
if [ "$(_db_r gifski dl_cur_url)" != "$GIFSKI" ]; then
  _tmp_init
  wget "$GIFSKI" -O gifski.zip
  unzip gifski.zip
  add_pkg_file linux/*.deb
  _tmp_exit
  _db_w gifski dl_cur_url "$GIFSKI"
fi

# Siderus Orion
# ORION_VERSION=$(curl "https://get.siderus.io/orion/latest-version")
# ORION="https://get.siderus.io/orion/orion_${ORION_VERSION}_amd64.deb"
# add_url_auto orion "$ORION"

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
add_from_repo "https://download.virtualbox.org/virtualbox/debian" "" "contrib" "virtualbox-6.0"
# x2go
# add_from_repo "http://ppa.launchpad.net/x2go/stable/ubuntu" "" "main" ""
# riot.im
add_from_repo "https://riot.im/packages/debian" "" "main" "riot-web"
# wireguard
for w in wireguard-tools wireguard-dkms wireguard; do # TODO: merge into one
  add_from_repo "http://ppa.launchpad.net/wireguard/wireguard/ubuntu" "" "main" "$w"
done

# IDE
add_gh_pkg atom atom/atom
add_gh_pkg vscodium VSCodium/vscodium

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
add_gh_pkg nuclear nukeop/nuclear "" "" "amd64"
add_gh_pkg curlie rs/curlie
add_gh_pkg keeweb keeweb/keeweb "" "" "amd64"
add_gh_pkg trilium zadam/trilium

# Self-compiled stuff
for url in $(curl -s https://i.mkg20001.io/deb/ | grep -o './.*deb\"' | sed "s|./|https://i.mkg20001.io/deb/|g" | sed 's|"||g'); do
  add_url_auto "$(echo $url | sed -r "s|.*deb/([a-z0-9.-]+)_.*|\1|g")" "$url"
done

# And... release

fin
