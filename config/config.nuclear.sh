#!/bin/bash

OUT="$PWD/nuclear"
KEY="A35AD290"

. "$CONFDIR/_functions.sh"

# Init Repo
_init

# Configure Repo
PPA_ARCHS="amd64 i386" # i386 is so dpkg doesn't complain about it being missing
add_dist "nuclear" "NUCLEAR" "Nuclear Music Player Repository"
add_comp "nuclear" stable
add_comp "nuclear" beta
for a in $PPA_ARCHS; do
  add_arch "nuclear" "$a"
done

add_gh_pkg_any nuclear nukeop/nuclear beta "" "amd64"
add_gh_pkg nuclear nukeop/nuclear stable "" "amd64"

# Release

fin
