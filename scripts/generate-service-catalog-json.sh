#!/usr/bin/env bash
#
# Description: Generate json from the service catalog, for ingestion in jsonnet
#

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")/../services"

generate() {
  source=$1
  target=$2

  if [[ ! -f "${target}" ]] || [[ ! -s "${target}" ]] || [[ "${source}" -nt "${target}" ]]; then
    # Update the service catalog
    ruby -rjson -ryaml -e "puts YAML.load(ARGF.read).to_json" "${source}" >"${target}"
  fi
}

generate "service-catalog.yml" "service_catalog.json"
