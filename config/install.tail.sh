#!/bin/bash

if [ -z "$REPO_CHANNEL" ]; then
  REPO_CHANNEL="##REPO_CHANNEL##"
fi

if [ -z "##REPO_DIST##" ] && [ -z "$REPO_DIST" ]; then
  if [ ! -x /usr/bin/lsb_release ]; then
    PKGS+=(lsb-release)
  fi

  prepare_pkgs

  DISTRO=$(lsb_release -c -s)
  REPO_DIST="$DISTRO"
  do_check_alt
elif [ -z "$REPO_DIST" ]; then
  REPO_DIST="##REPO_DIST##"
  prepare_pkgs
else
  prepare_pkgs
fi

REPO_BASE="##REPO_BASE##"
LIST_FILE="##LIST_FILE##"

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
