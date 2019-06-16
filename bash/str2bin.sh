#!/usr/bin/env bash
err() {
  echo -e "\033[1;31m$1\033[0m"
  exit 1
}

str2bin() {
  if [[ -z $1 || $# -gt 1 ]]; then
    err 'Index is out of range.'
  fi

  bin=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
  for (( i=0; i < ${#1}; i++ )); do
    res+=${bin[$(printf %d "'${1:i:1}'")]}
  done
  echo $res
}

bin2str() {
  if [[ -z $1 || $# -gt 1 ]]; then
    err 'Index is out of range.'
  fi

  for (( i=0; i < ${#1}; i+=8 )); do
    res+=$(printf %b `printf '\x%x' $((2#${1:i:8})) 2>/dev/null`)
  done
  echo $res
}
