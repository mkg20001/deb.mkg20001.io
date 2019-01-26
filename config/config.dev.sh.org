#!/bin/bash

OUT="/tmp/ubuntu"
KEY="E90CBA3455B36236740C038F0D948CE19CF49C5F"

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

# DEV #

fin
