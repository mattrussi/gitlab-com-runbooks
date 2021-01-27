#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "${BASH_SOURCE[0]}")/.."

find_jsonnet() {
  find "." \( -name '*.jsonnet' -o -name '*.libsonnet' \) -not -path './vendor/*' | grep -v './rules-jsonnet/saturation.jsonnet'
}

filtered_lint() {
  (jsonnet-lint -J "./libsonnet" -J "./vendor" -J "./services" -J "./metrics-catalog" -J "./dashboards" "$1" 2>&1 || true)
}

find_jsonnet | while read -r line; do
  echo "# ${line}"
  if ! filtered_lint "$line"; then
    echo "# ${line} failed"
    exit 1
  fi
done
