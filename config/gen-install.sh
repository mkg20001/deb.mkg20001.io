#!/bin/bash

gen_check() {
  echo "do_check_alt() {"
  curl -s https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_10.x | grep "^check_alt " | sed "s|^|  |g"
  echo "}"
}

gen_file() {
  cat install.head.sh
  if [ -z "$3" ]; then
    echo
    gen_check
    echo
  fi
  cat install.tail.sh | sed "s|#!.*||g" | sed "s|##LIST_FILE##|$1|g" | sed "s|##REPO_BASE##|$2|g" | sed "s|##REPO_DIST##|$3|g" | sed "s|##REPO_CHANNEL##|$4|g"
  echo "setup"
}

gen_file mkg ubuntu "" main > ../install.sh
gen_file nuclear nuclear nuclear beta > ../nuclear.sh
