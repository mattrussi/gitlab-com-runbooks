#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)

# Check that jsonnet-tool is installed
"${REPO_DIR}/scripts/ensure-jsonnet-tool.sh"

function render_multi_jsonnet() {
  local dest_dir="$1"
  local filename="$2"
  local warning="# WARNING. DO NOT EDIT THIS FILE BY HAND. USE ${filename} TO GENERATE IT
# YOUR CHANGES WILL BE OVERRIDDEN"

  jsonnet-tool yaml \
    --multi "$dest_dir" \
    --header "${warning}" \
    -J "${REPO_DIR}/libsonnet/" \
    -J "${REPO_DIR}/metrics-catalog/" \
    -J "${REPO_DIR}/services/" \
    -J "${REPO_DIR}/vendor/" \
    -P name -P interval -P partial_response_strategy -P rules \
    -P alert -P for -P annotations -P record -P labels -P expr \
    -P title -P description \
    --prefix "autogenerated-" \
    "${filename}"
}

if [[ $# == 0 ]]; then
  cd "${REPO_DIR}"
  for file in ./rules-jsonnet/*.jsonnet; do
    render_multi_jsonnet "${REPO_DIR}/rules" "${file}"
  done
  for file in ./thanos-rules-jsonnet/*.jsonnet; do
    render_multi_jsonnet "${REPO_DIR}/thanos-rules" "${file}"
  done
  for file in ./thanos-staging-rules-jsonnet/*.jsonnet; do
    render_multi_jsonnet "${REPO_DIR}/thanos-staging-rules" "${file}"
  done
else
  for file in "$@"; do
    source_dir=$(dirname "${file}")
    render_multi_jsonnet "${source_dir%-jsonnet}" "${file}"
  done
fi

# Update generated rules to CRD spec
${REPO_DIR}/scripts/generate-prometheus-crd.rb thanos-staging-rules