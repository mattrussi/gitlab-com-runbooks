#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function es_client() {
  url=$1
  shift
  curl --retry 3 --fail -H 'Content-Type: application/json' "${ES_URL}/${url}" "$@"
}

function kibana_client() {
  url=$1
  shift
  curl --retry 3 --fail -H 'Content-Type: application/json' -H 'kbn-xsrf: true' "${KIBANA_URL}/${url}" "$@"
}

function execute_jsonnet() {
  jsonnet -J "${SCRIPT_DIR}/../../lib" \
    -J "${SCRIPT_DIR}/../../../../libsonnet" \
    "$@"
}

function matches_exist() {
  [ -e "$1" ]
}

function get_json_and_jsonnet() {
  export array_file_path="/tmp/get_json_and_jsonnet.array"
  json_array=()

  if matches_exist "${SCRIPT_DIR}"/*.json; then
    for i in "${SCRIPT_DIR}"/*.json; do
      json_content=$(jq -c '.' "${i}")
      json_array+=("${json_content}")
    done
  fi

  if matches_exist "${SCRIPT_DIR}"/*.jsonnet; then
    for i in "${SCRIPT_DIR}"/*.jsonnet; do
      json_content="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
      json_array+=("${json_content}")
    done
  fi

  if [ ${#json_array[@]} -eq 0 ]; then
    echo "No json or jsonnet files found."
    exit 1
  fi

  declare -p json_array >"${array_file_path}"
}

# ES5
################################################################################

function ES5_watches_upload_json() {
  for i in "${SCRIPT_DIR}"/*.json; do
    base_name=$(basename "$i")
    echo ""
    echo "$base_name"
    name=${base_name%.json}
    es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "@${i}"
  done
}

function ES5_watches_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo ""
    echo "$base_name"
    name=${base_name%.jsonnet}
    watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_xpack/watcher/watch/${name}?pretty=true" -X PUT --data-binary "${watch_json}"
  done
}

# ES7
################################################################################
function ES7_put_json() {
  # args:
  # $1 URL to use when uploading
  for i in "${SCRIPT_DIR}"/*.json; do
    if [[ -e $i ]]; then
      base_name=$(basename "$i")
      echo ""
      echo "$base_name"
      name=${base_name%.json}
      es_client "$1${name}" -X PUT --data-binary "@${i}"
    fi
  done
}

function kibana_post_json() {
  # args:
  # $1 URL to use when uploading
  for i in "${SCRIPT_DIR}"/*.json; do
    base_name=$(basename "$i")
    echo ""
    echo "$base_name"
    name=${base_name%.json}
    kibana_client "$1${name}" -X POST --data-binary "@${i}"
  done
}

function kibana_put_json() {
  # args:
  # $1 URL to use when uploading
  for i in "${SCRIPT_DIR}"/*.json; do
    base_name=$(basename "$i")
    echo ""
    echo "$base_name"
    name=${base_name%.json}
    kibana_client "$1${name}" -X PUT --data-binary "@${i}"
  done
}
function ES7_watches_exec_jsonnet_and_upload_json() {
  files=$(find "${SCRIPT_DIR}" -type f -name '*.jsonnet')
  if [ -n "$files" ]; then
    for i in $files; do
      base_name=$(basename "$i")
      echo ""
      echo "$base_name"
      name=${base_name%.jsonnet}
      watch_json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
      es_client "_watcher/watch/${name}" -X PUT --data-binary "${watch_json}"
    done
  else
    echo "No watch definitions found. Not uploading anything to the cluster."
  fi
}

function ES7_ILM_exec_jsonnet_and_upload_json() {
  for i in "${SCRIPT_DIR}"/*.jsonnet; do
    base_name=$(basename "$i")
    echo ""
    echo "$base_name"
    name=${base_name%.jsonnet}
    json="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
    es_client "_ilm/policy/${name}" -X PUT --data-binary "${json}"
  done
}

function ES7_index-template_exec_jsonnet_and_upload_json() {
  json=$(execute_jsonnet -e "local generic_index_template = import '$1'; generic_index_template.get('$2', '$3')")
  json_file="/tmp/es_tmp_$(date +"%Y%m%d-%H%M%S").json"
  echo "${json}" >"$json_file"
  url="_template/gitlab_pubsub_$2_inf_$3_template"
  echo "${url}"
  es_client "${url}" -X PUT --data "@$json_file"
  rm "$json_file"
}

function ES7_set_cluster_settings() {
  url="_cluster/settings"
  get_json_and_jsonnet
  # shellcheck disable=SC1090
  source "${array_file_path}"

  for json in "${json_array[@]}"; do
    es_client "${url}" -X PUT --data-binary "${json}"
  done
}
