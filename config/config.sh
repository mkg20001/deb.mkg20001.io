#!/bin/bash

OUT="$PWD/ubuntu"
KEY="A35AD290"

get_repo_clear() {
  rfile_sucess=false
  PKG_DATA=$(wget -qO- "$REPO/dists/$DISTR/binary-$arch/Packages" || ex=$?)
  if [ $ex -ne 0 ] || [ -z "$PKG_DATA" ]; then
    # try xz instead
    PKG_DATA=$(wget -qO- "$REPO/dists/$DISTR/binary-$arch/Packages.xz" || ex=$?)
    if [ $ex -ne 0 ] || [ -z "$PKG_DATA" ]; then
      return 0
    else
      PKG_DATA=$(wget -qO- "$REPO/dists/$DISTR/binary-$arch/Packages.xz" | xzcat)
      if [ ! -z "$PKG_DATA" ]; then
        rfile_sucess=true
      fi
    fi
  else
    rfile_sucess=true
  fi
}

add_from_repo() {
  REPO="$1"
  DISTR_NAMES="$2"
  DISTR_CHANNEL="$3"
  PKG="$4"

  DIST_ITER=false

  if [ -z $DISTR_NAMES ]; then # if empty iterate over all dists
    DIST_ITER=true
    DISTR_NAMES="$PPA_DISTS"
  fi

  REPO_DB=$(echo "$REPO" | sed "s|[^a-z0-9]|-|g" | sed "s|^|CACHE_ppasc_rp_cl_|g")

  log "repo->$PKG: Updating from $REPO"
  for arch in $ARCHS; do
    ex=0

    _db_w "$REPO_DB" "last_success_$arch" ""

    for DISTR_NAME in $DISTR_NAMES; do
      DISTR="$DISTR_NAME/$DISTR_CHANNEL"
      dr_display="$DISTR_NAME"

      ls=$(_db_r "$REPO_DB" "last_success_$arch") # use newest or latest successful

      done=false
      firstFail=false
      secondFail=false

      while ! $done && ! $secondFail; do
        if $firstFail; then
          secondFail=true
        fi

        get_repo_clear

        if ! $rfile_success; then
          log "repo->$PKG->$dr_display->$arch: Did not find anything for binary-$arch"

          if [ ! -z "$ls" ]; then
            log "repo->$PKG->$dr_display->$arch: Trying again using $ls"
            DISTR="$ls/$DISTR_CHANNEL"
            dr_display="$DISTR_NAME\$$ls"
            firstFail=true
          else
            secondFail=true
          fi
        else
          PKG_JSON=$(echo "$PKG_DATA" | sed "s|\"|\\\"|g" | sed -r "s|^ .+$||g" | sed -r "s|^([A-Z][A-Za-z0-9-]+): (.*)|\"\1\": \"\2\",|g" | sed "s|^$|\"_\":1},{|g" )
          PKG_JSON="[{$PKG_JSON\"_\":1}]"
          PKG_URL=$(echo "$PKG_JSON" | jq -r "map(select(.Package == \"$PKG\"))[] | .Filename" | sort -r | head -n 1)
          if [ -z "$PKG_URL" ]; then
            log "repo->$PKG->$dr_display->$arch: Found binary-$arch, but did not contain $PKG"

            if [ ! -z "$ls" ]; then
              log "repo->$PKG->$dr_display->$arch: Trying again using $ls"
              DISTR="$ls/$DISTR_CHANNEL"
              dr_display="$DISTR_NAME\$$ls"
              firstFail=true
            else
              secondFail=true
            fi
          else
            PKG_URL="$REPO/$PKG_URL"
            log "repo->$PKG->$dr_display->$arch: Latest is $PKG_URL"
            done=true
            if $DIST_ITER; then
              _db_w "$REPO_DB" "last_success_$arch" "$DISTR_NAME"
              add_url "$PKG" "$PKG_URL" "$arch" "" "$DISTR_NAME"
            else
              add_url "$PKG" "$PKG_URL" "$arch"
            fi
          fi
        fi
      done


      if [ ! -z "$ls" ] && ! $rfile_success; then
        log "repo->$PKG->$dr_display->$arch: Did not find anything for binary-$arch $DISTR_NAME, trying $ls"
        get_repo_clear
      fi

    done
  done
}

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

# Stub (these pkgs will add own repo after install)
## Chrome
add_from_repo "https://dl.google.com/linux/chrome/deb" "stable" "main" "google-chrome-stable"
## Keybase
add_from_repo "https://prerelease.keybase.io/deb" "stable" "main" "keybase"
## Syncthing
add_from_repo "https://apt.syncthing.net" "syncthing" "stable" "syncthing"

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
add_from_repo "http://ppa.launchpad.net/sil/pick/ubuntu" "" "main" "pick-colour-picker"
add_gh_pkg lanshare abdularis/lan-share

# Self-compiled stuff
for url in $(curl -s https://i.mkg20001.io/deb/ | grep -o './.*deb\"' | sed "s|./|https://i.mkg20001.io/deb/|g" | sed 's|"||g'); do
  add_url_auto "$(echo $url | sed -r "s|.*deb/([a-z0-9.-]+)_.*|\1|g")" "$url"
done

# small-cleanup-script
add_from_repo "http://ppa.launchpad.net/mkg20001/stable/ubuntu" "" "main" "small-cleanup-script"

# And... release

fin
