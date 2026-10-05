#!/usr/bin/env bash
# Shared helpers for multi-ISO live trees (sourced by other scripts).
# shellcheck shell=bash

iso_stem() {
  local base
  base="$(basename "$1")"
  echo "${base%.iso}"
}

# Print: kind|title|layerfs_installer|layerfs_alt
# kind: server | desktop | unknown
detect_casper_profile() {
  local casper="$1"
  local title="Ubuntu live"
  local info="${casper}/../.disk/info"
  if [[ -f "${info}" ]]; then
    title="$(tr -d '\n' <"${info}" | sed 's/ - Release.*//; s/"//g')"
  fi

  if [[ -f "${casper}/ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs" ]]; then
    echo "server|${title}|ubuntu-server-minimal.ubuntu-server.installer.generic.squashfs|ubuntu-server-minimal.ubuntu-server.squashfs"
    return 0
  fi
  if [[ -f "${casper}/minimal.standard.live.squashfs" ]]; then
    echo "desktop|${title}|minimal.standard.live.squashfs|minimal.squashfs"
    return 0
  fi
  local first
  first="$(find "${casper}" -maxdepth 1 -name '*.squashfs' -printf '%f\n' | head -1 || true)"
  if [[ -n "${first}" ]]; then
    echo "unknown|${title}|${first}|"
    return 0
  fi
  return 1
}
