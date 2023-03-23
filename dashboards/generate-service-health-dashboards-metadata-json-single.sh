#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}" || exit

source "grafana-tools.lib.sh"

if [[ -e .env.sh ]]; then
  source ".env.sh"
fi

IFS=$'\n\t'

filename="$1"
relative=${filename#"./"}
folder=${GRAFANA_FOLDER:-$(dirname "$relative")}

cat "generated/$filename" | jq -c | while IFS= read -r dashboard; do
  # Use http1.1 and gzip compression to workaround unexplainable random errors that
  # occur when uploading some dashboards
  uid=$(echo "${dashboard}" | jq -r '.uid')
  if response=$(call_grafana_api "https://dashboards.gitlab.net/api/dashboards/uid/$uid"); then
    url=$(echo "${response}" | jq '.meta.url' | tr -d '"')
    fullurl="https://dashboards.gitlab.net$url"
    echo "${folder},${fullurl}"
  fi
  echo >&2 "Processed dashboards for $uid"
done
