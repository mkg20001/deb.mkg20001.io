#!/bin/bash

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
              if ! $firstFail; then
                _db_w "$REPO_DB" "last_success_$arch" "$DISTR_NAME"
              else
                _db_w "$REPO_DB" "ls_$DISTR_NAME@$arch" "true"
              fi
              lsp=$(_db_r "$REPO_DB" "ls_$DISTR_NAME@$arch")
              if [ ! -z "$lsp" ]; then # if first was $ls then do this to prevent accidental override
                IGNORE_RM=true
              fi
              add_url "$PKG" "$PKG_URL" "$arch" "" "$DISTR_NAME"
              if $IGNORE_RM && [ -z "$ls" ]; then
                _db_w "$REPO_DB" "ls_$DISTR_NAME@$arch" ""
              fi
              IGNORE_RM=false
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

rp_init() {
  RP_NAME="$1"
  RP_URL="$2"
  RP_CONTINUE=false

  if [ "$(_db_r $RP_NAME rp_cur_url)" != "$RP_URL" ]; then
    log "repackage->$RP_NAME: Generating from $RP_URL"
    RP_CONTINUE=true

    _tmp_init

    RP_FILE=$(basename "$RP_URL")
    wget "$RP_URL" --progress=dot:giga -O "$RP_FILE"
  else
    log "repackage->$RP_NAME: Used cached file $(_db_r $RP_NAME rp_cur_file) for $RP_URL"
  fi
}

rp_finish() {
  log "repackage->$RP_NAME: Converting $RP_TAR into deb"

  fakeroot alien -v -d --target=amd64 --fixperms "$RP_TAR"
  DEB=$(ls | grep ".deb$")

  log "repackage->$RP_NAME: Generated $DEB!"
  _db_w "$RP_NAME" rp_cur_url "$RP_URL"

  OLD_DEB=$(_db_r "$RP_NAME" rp_cur_file)
  if [ ! -z "$OLD_DEB" ]; then
    rm_pkg_file "$OLD_DEB"
  fi
  add_pkg_file "$DEB"

  _db_w "$RP_NAME" rp_cur_file "$DEB"
  _tmp_exit
}
