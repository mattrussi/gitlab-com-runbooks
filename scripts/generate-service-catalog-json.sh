#!/usr/bin/env bash
#
# Description: Generate json from the service catalog, for ingestion in jsonnet
#

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")/../services"

generate() {
  # output the service catalog files
  ruby -rjson -ryaml -e "puts YAML.load(ARGF.read).to_json" "$@"
}

generate "service-catalog.yml" "teams.yml" >"service_catalog.json"
