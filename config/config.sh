#!/bin/bash

OUT="$PWD/ubuntu"
KEY="A35AD290"

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

# Chrome (after install it will add it's own repo)
chrome=$(curl --silent https://dl.google.com/linux/chrome/deb/dists/stable/main/binary-amd64/Packages | grep "google-chrome-stable/" | sed "s|.*pool|https://dl.google.com/linux/chrome/deb/pool|g")
add_url_auto google-chrome-stable "$chrome"

# IDE
add_gh_pkg atom atom/atom

# P2P
add_gh_pkg lbry lbryio/lbry-desktop "" "" "amd64"
add_gh_pkg webtorrent webtorrent/webtorrent-desktop
add_gh_pkg ipfs-desktop ipfs-shipyard/ipfs-desktop
add_gh_pkg pathephone pathephone/pathephone-desktop
add_gh_pkg_any tribler tribler/tribler
add_gh_pkg orion siderus/orion

# Cloud
add_gh_pkg minikube kubernetes/minikube "" "" "amd64"

# Social media
add_gh_pkg akasha AkashaProject/Community
add_gh_pkg talenet talenet/talenet

# Other
add_url multimc "https://files.multimc.org/downloads/multimc_1.2-1.deb" all
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