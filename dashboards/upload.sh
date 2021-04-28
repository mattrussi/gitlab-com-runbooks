#!/usr/bin/env bash
# vim: ai:ts=2:sw=2:expandtab

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

source "grafana-tools.lib.sh"

usage() {
  cat <<-EOF
  Usage $0 [Dh]

  DESCRIPTION
    This script generates dashboards and uploads
    them to dashboards.gitlab.net

    GRAFANA_API_TOKEN must be set in the environment

    GRAFANA_FOLDER (optional): Override folder.
    Useful for testing.

  FLAGS
    -D  run in Dry-run
    -h  help

EOF
}

while getopts ":Dh" o; do
  case "${o}" in
    D)
      dry_run="true"
      ;;
    h)
      usage
      exit 0
      ;;
    *) ;;

  esac
done

shift $((OPTIND - 1))

dry_run=${dry_run:-}

if [[ -z $dry_run && -z ${GRAFANA_API_TOKEN:-} ]]; then
  echo "You must set GRAFANA_API_TOKEN to use this script, or run in dry run mode"
  usage
  exit 1
fi

prepare

function validate_dashboard_requests() {
  while IFS= read -r request; do
    uid=$(echo "${request}" | jq -r '.uid')
    if [[ ${#uid} -gt 40 ]]; then
      echo >&2 "UID ${uid} is longer than the 40 char max allowed by Grafana"
      return 1
    fi
    echo "${request}"
  done
}

function generate_dashboard_requests() {
  find_dashboards "$@" | while read -r line; do
    relative=${line#"./"}
    folder=${GRAFANA_FOLDER:-$(dirname "$relative")}
    folderId=$(resolve_folder_id "${folder}")

    generate_dashboards_for_file "${line}" | validate_dashboard_requests | prepare_dashboard_requests "${folderId}" | (
      if [[ -n $dry_run ]]; then
        jq -r --arg file "$line" --arg folder "$folder" '"Running in dry run mode, would create \($file) in folder \($folder) with uid \(.dashboard.uid)"'
      else
        cat
      fi
    )
  done
}

if [[ -n $dry_run ]]; then
  generate_dashboard_requests "$@"
else
  tmpfile=$(mktemp)
  trap 'rm -rf "${tmpfile}"' EXIT

  generate_dashboard_requests "$@" | while IFS= read -r request; do
    uid=$(echo "${request}" | jq -r '.dashboard.uid')
    # Use http1.1 and gzip compression to workaround unexplainable random errors that
    # occur when uploading some dashboards
    response=$(echo "${request}" | call_grafana_api https://dashboards.gitlab.net/api/dashboards/db -d @-) || {
      echo >&2 ""
      echo >&2 "Failed to upload '${uid}'"
      exit 1
    }

    url=$(echo "${response}" | jq -r '.url')
    echo "Installed https://dashboards.gitlab.net${url}"
    echo "${url}" >>"${tmpfile}"
  done

  duplicates=$(sort "${tmpfile}" | uniq -d)
  if [[ -n $duplicates ]]; then
    echo "Duplicate dashboard URLs were uploaded! Check these URLs:"
    echo "${duplicates}"
    exit 1
  fi
fi
