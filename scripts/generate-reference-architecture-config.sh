#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function main() {
  REPO_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
  )

  # Check that jsonnet-tool is installed
  "${REPO_DIR}/scripts/ensure-jsonnet-tool.sh"

  local params=()

  # Pass a header via GL_GENERATE_CONFIG_HEADER
  if [[ -n ${GL_GENERATE_CONFIG_HEADER:-} ]]; then
    params+=(--header "${GL_GENERATE_CONFIG_HEADER}")
  fi

  if [[ $# -eq 2 ]] || [[ $# -eq 3 ]]; then
    reference_architecture_src_dir="$1"
    dest_dir="$2"

    if [[ $# -eq 3 ]]; then
      overrides_dir="$3"
      params+=("-J" "${overrides_dir}")
    fi
  else
    echo "$# is "
    usage
  fi

  set -x
  jsonnet-tool render \
    --multi "$dest_dir" \
    -J "${REPO_DIR}/libsonnet/" \
    -J "${REPO_DIR}/reference-architectures/default-overrides" \
    -J "${reference_architecture_src_dir}" \
    -J "${REPO_DIR}/vendor/" \
    "${params[@]}" \
    "${reference_architecture_src_dir}/generate.jsonnet"
}

function usage() {
  cat >&2 <<-EOD
$0 source_dir output_dir [overrides_dir]
Generate prometheus rules and grafana dashboards for a reference architecture.

  * source_dir: the Jsonnet source directory containing the configuration.
  * output_dir: the directory in which generated configuration should be emitted
  * overrides_dir: [optional] the directory containing any Jsonnet source file overrides

For detailed instructions on using this command, please refer to the README.md file at
https://gitlab.com/gitlab-com/runbooks/-/blob/master/reference-architectures/README.md.
EOD

  exit 1
}

main "$@"
