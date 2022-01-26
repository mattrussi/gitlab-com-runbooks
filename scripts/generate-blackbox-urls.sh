#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

BLACKBOX_MONITORING_DIR=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/../blackbox-monitoring/"
  pwd
)

rm -rf "${BLACKBOX_MONITORING_DIR}/lists"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/desktop/loggedinurls"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/desktop/urls"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/dev/urls"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/emulatedMobile/urls/"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/gitter/urls/"
mkdir -p "${BLACKBOX_MONITORING_DIR}/lists/sitespeed/www-about/urls/"

jsonnet --string --multi "${BLACKBOX_MONITORING_DIR}/lists/" "${BLACKBOX_MONITORING_DIR}/blackbox-monitoring.jsonnet"
