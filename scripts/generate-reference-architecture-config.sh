#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function main() {
  REPO_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
  )

  cd "${REPO_DIR}"

  # Check that jsonnet-tool is installed
  "${REPO_DIR}/scripts/ensure-jsonnet-tool.sh"

  local params=()
  local paths=()

  # Pass a header via GL_GENERATE_CONFIG_HEADER
  if [[ -n ${GL_GENERATE_CONFIG_HEADER:-} ]]; then
    params+=(--header "${GL_GENERATE_CONFIG_HEADER}")
  fi

  if [[ $# -eq 2 ]] || [[ $# -eq 3 ]]; then
    reference_architecture_src_dir="$1"
    dest_dir="$2"

    if [[ $# -eq 3 ]]; then
      overrides_dir="$3"
      paths+=("-J" "${overrides_dir}")
    fi
  else
    echo "$# is "
    usage
  fi

  local source_file="${reference_architecture_src_dir}/generate.jsonnet"
  local sha256sum_file="${REPO_DIR}/.cache/$source_file.sha256sum"
  local cache_out_file="${REPO_DIR}/.cache/$source_file.out"

  if [[ "${GL_JSONNET_CACHE_SKIP:-}" != 'true' ]]; then
    mkdir -p "$(dirname "$sha256sum_file")" "$(dirname "$cache_out_file")"

    if [[ -f "$cache_out_file" ]] && [[ -f "$sha256sum_file" ]] && sha256sum --check --status <"$sha256sum_file"; then
      for file in $(cat "$cache_out_file"); do
        mkdir -p "$(dirname "$file")"
        cp "${REPO_DIR}/.cache/$file" "$file"
      done
      cat "$cache_out_file"
      return 0
    fi

    if [[ "${GL_JSONNET_CACHE_DEBUG:-}" == 'true' ]]; then
      echo >&2 "jsonnet_cache: miss: $source_file"
    fi
  fi

  out="$(
    jsonnet-tool render \
      --multi "$dest_dir" \
      -J "${REPO_DIR}/libsonnet/" \
      -J "${REPO_DIR}/reference-architectures/default-overrides" \
      -J "${reference_architecture_src_dir}" \
      -J "${REPO_DIR}/vendor/" \
      "${paths[@]}" \
      "${params[@]}" \
      "$source_file"
  )"
  echo "$out"

  if [[ "${GL_JSONNET_CACHE_SKIP:-}" != 'true' ]]; then
    echo "$out" >"$cache_out_file"
    for file in $out; do
      mkdir -p "$(dirname "${REPO_DIR}/.cache/$file")"
      cp "$file" "${REPO_DIR}/.cache/$file"
    done
    jsonnet-deps \
      -J "${REPO_DIR}/metrics-catalog/" \
      -J "${REPO_DIR}/dashboards/" \
      -J "${REPO_DIR}/libsonnet/" \
      -J "${REPO_DIR}/reference-architectures/default-overrides" \
      -J "${reference_architecture_src_dir}" \
      -J "${REPO_DIR}/vendor/" \
      "${paths[@]}" \
      "$source_file" | xargs sha256sum >"$sha256sum_file"
    echo "$source_file" "${REPO_DIR}/.tool-versions" | xargs realpath | xargs sha256sum >>"$sha256sum_file"
  fi
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
