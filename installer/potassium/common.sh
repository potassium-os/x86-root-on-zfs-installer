#!/bin/false
# shellcheck shell=bash

# This file is intended to be sourced, not executed

function _log () {
  NOW=$(date +"%T")
  echo "[${NOW}]" "$@" >> "${HOME}/installer.log"
  echo "[${NOW}]" "$@" >> /dev/tty
}
