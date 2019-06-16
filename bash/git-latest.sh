#!/usr/bin/env bash

# verify runtime environment (should be MINGW)
IS_MINGW="$(uname | cut -c1-5)"
case ${IS_MINGW,,} in
  "mingw")
    # construct available version search pattern
    REX="https:[^"'"'"]*-${MSYSTEM/$IS_MINGW/}-bit.7z.exe"
    # locate actual package download link
    PKG=$(curl -s https://git-scm.com/download/win | grep -oP $REX)
    # compare versions
    if $(echo $PKG | grep -qo "v$(git --version | grep -oP '(\d+\.){2}.*')")
    then
      echo -e "\033[1;36mYou are using actual Git version.\033[0m"
    else
      # be sure that download path does exist
      [[ -d ~/git-pkg ]] || mkdir ~/git-pkg
      # show version of downloadable package
      VER=$(echo $PKG | grep -oP '^.*?\K(\d+\.){2}\d+')
      echo -e "\033[1;33mCurrent Git version is ${VER}...\033[0m"
      # jsut download
      pushd ~/git-pkg >/dev/null
      curl -LO "${PKG}"
      popd >/dev/null
    fi
  ;;
  *) echo -e "\033[1;31mEnvironment error.\033[0m";;
esac
