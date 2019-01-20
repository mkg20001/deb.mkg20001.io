#!/bin/bash

OUT="$PWD/nuclear"
KEY="A35AD290"

. "$(dirname $(readlink -f $0))/_functions.sh"

# Init Repo
_init

# Configure Repo
PPA_ARCHS="amd64 i386" # i386 is so dpkg doesn't complain about it being missing
add_dist "main" "NUCLEAR" "Nuclear Music Player Repository"
add_comp "main" stable
add_comp "main" beta
for a in $PPA_ARCHS; do
  add_arch "$distro" "$a"
done

add_gh_pkg_any nuclear nukeop/nuclear beta
add_gh_pkg nuclear nukeop/nuclear stable

# Release

fin
