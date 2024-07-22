#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function main() {
  REPO_DIR=$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
  )

  echo "Repository Directory: ${REPO_DIR}"

  cd "${REPO_DIR}"

  # Check that jsonnet-tool is installed
  "${REPO_DIR}/scripts/ensure-jsonnet-tool.sh"

  local params=()
  local paths=()

  mixins_src_dir="${REPO_DIR}/mixins-monitoring"
  echo "Mixin Source Directory: ${mixins_src_dir}"

  # Pass a header via GL_GENERATE_CONFIG_HEADER
  if [[ -n ${GL_GENERATE_CONFIG_HEADER:-} ]]; then
    params+=(--header "${GL_GENERATE_CONFIG_HEADER}")
  fi

  # Validate input arguments
  if [[ $# -eq 2 ]] || [[ $# -eq 3 ]]; then
    local reference_architecture_src_dir="$1"
    local dest_dir="$2"

    echo "Reference Architecture Source Directory: ${reference_architecture_src_dir}"
    echo "Destination Directory: ${dest_dir}"

    if [[ $# -eq 3 ]]; then
      overrides_dir="$3"
      paths+=("-J" "${overrides_dir}")
      echo "Overrides Directory: ${overrides_dir}"
    fi
  else
    echo "Invalid number of arguments: $#"
    usage
  fi

  local source_file="${reference_architecture_src_dir}/generate.jsonnet"
  local args_hash="$(echo "$@" | sha256sum | awk '{ print $1 }')"
  local sha256sum_file="${REPO_DIR}/.cache/$source_file.$args_hash.sha256sum"
  local cache_out_file="${REPO_DIR}/.cache/$source_file.$args_hash.out"

  echo "Source File: ${source_file}"
  echo "SHA256 Sum File: ${sha256sum_file}"
  echo "Cache Output File: ${cache_out_file}"

  if [[ ${GL_JSONNET_CACHE_SKIP:-} != 'true' ]]; then
    setup_cache_directories "$sha256sum_file" "$cache_out_file"

    if cache_hit "$sha256sum_file" "$cache_out_file"; then
      restore_cache "$cache_out_file"
      return 0
    fi

    [[ ${GL_JSONNET_CACHE_DEBUG:-} == 'true' ]] && echo >&2 "jsonnet_cache: miss: $source_file"
  fi

  local out=$(generate_output "$dest_dir" "$source_file" "${paths[@]}" "${params[@]}")
  echo "$out"

  if [[ ${GL_JSONNET_CACHE_SKIP:-} != 'true' ]]; then
    save_cache "$out" "$cache_out_file"
    update_cache "$source_file" "$sha256sum_file"
  fi

  generate_mixins "$mixins_src_dir" "${paths[1]}" "$dest_dir"
}

function setup_cache_directories() {
  local sha256sum_file="$1"
  local cache_out_file="$2"
  mkdir -p "$(dirname "$sha256sum_file")" "$(dirname "$cache_out_file")"
}

function cache_hit() {
  local sha256sum_file="$1"
  local cache_out_file="$2"
  [[ -f $cache_out_file ]] && [[ -f $sha256sum_file ]] && sha256sum --check --status <"$sha256sum_file"
}

function restore_cache() {
  local cache_out_file="$1"
  while IFS= read -r file; do
    mkdir -p "$(dirname "$file")"
    cp "${REPO_DIR}/.cache/$file" "$file"
  done < "$cache_out_file"
  cat "$cache_out_file"
}

function generate_output() {
  local dest_dir="$1"
  local source_file="$2"
  shift 2
  local params=("$@")
  local paths=()
  jsonnet-tool render \
    --multi "$dest_dir" \
    -J "${REPO_DIR}/libsonnet/" \
    -J "${REPO_DIR}/reference-architectures/default-overrides" \
    -J "${reference_architecture_src_dir}" \
    -J "${REPO_DIR}/vendor/" \
    "${paths[@]}" \
    "${params[@]}" \
    "$source_file"
}

function save_cache() {
  local out="$1"
  local cache_out_file="$2"
  echo "$out" >"$cache_out_file"
  while IFS= read -r file; do
    mkdir -p "$(dirname "${REPO_DIR}/.cache/$file")"
    cp "$file" "${REPO_DIR}/.cache/$file"
  done <<< "$out"
}

function update_cache() {
  local source_file="$1"
  local sha256sum_file="$2"
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
}

function generate_mixins() {
  local mixins_src_dir="$1"
  local overrides_dir="$2"
  local dest_dir="$3"

  if [[ -f "$overrides_dir/mixins.libsonnet" ]]; then
    local original_dir=$(pwd)

    jsonnet "$overrides_dir/mixins.libsonnet" | jq -r '.mixins[]' | while IFS= read -r mixin; do
      echo "$mixins_src_dir/$mixin"
      cd "$mixins_src_dir/$mixin"
      jb install -q
      mixtool generate all "-J" "vendor" "-J" "vendor/gitlab.com/gitlab-com/runbooks/libsonnet" \
        -d "$dest_dir/dashboards" \
        -r "$dest_dir/prometheus-rules/${mixin}.rules.yaml" \
        -a "$dest_dir/prometheus-rules/${mixin}.alerts.yaml" \
        -y "$mixins_src_dir/$mixin/mixin.libsonnet"
    done

    cd "$original_dir"
  else
    echo "mixins.libsonnet file does not exist in $overrides_dir"
  fi
}

function usage() {
  cat >&2 <<-EOD
$0 source_dir output_dir [overrides_dir]
Generate mixins, prometheus rules and grafana dashboards for a reference architecture.

  * source_dir: the Jsonnet source directory containing the configuration.
  * output_dir: the directory in which generated configuration should be emitted
  * overrides_dir: [optional] the directory containing any Jsonnet source file overrides

For detailed instructions on using this command, please refer to the README.md file at
https://gitlab.com/gitlab-com/runbooks/-/blob/master/reference-architectures/README.md.
EOD

  exit 1
}

main "$@"
