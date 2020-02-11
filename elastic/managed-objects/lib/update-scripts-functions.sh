#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function es_watch_api_path() {
  if [[ $# -eq 1 || "$1" == '-5' ]]; then
    # ES 5 watch API path.
    echo '_xpack/watcher/watch'
  else
    # Default: ES 7 watch API path.
    echo '_watcher/watch'
  fi
}

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
  # MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS should be comma-delimited
  jsonnet -J "${SCRIPT_DIR}/../../lib" \
    --ext-str "marquee_customers_top_level_domains=${MARQUEE_CUSTOMERS_TOP_LEVEL_DOMAINS:-}" \
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

function es_upload_json_files() {
  if [[ $# -le 2 ]]; then
    echo "usage: ${FUNCNAME-${0}} <api path> <list of json or jsonnet files>"
    return 0
  fi
  local api_path="$1"
  shift 1

  local base_name extension file
  for file in "$@"; do
    base_name="$(basename "${file}")"
    extension="${file##*.}"
    echo ""
    echo "${base_name}"

    case "${extension}" in
      json)
        name="${base_name%.json}"
        json_data="@${file}"
        ;;
      jsonnet)
        name="${base_name%.jsonnet}"
        json_data="$(execute_jsonnet "${i}" | jq -c '.')" # Compile jsonnet and compact with jq
        ;;
      *)
        echo "ERROR: Invalid extension (${extension}) on file ${file}"
        return 1
        ;;
    esac
    es_client "${api_path}/${name}?pretty=true" -X PUT --data-binary "${json_data}"
  done
}

# ES5
################################################################################

function ES5_watches_upload_json() {
  es_upload_json_files "$(es_watch_api_path -5)" "${SCRIPT_DIR}"/*.json
}

function ES5_watches_exec_jsonnet_and_upload_json() {
  es_upload_json_files "$(es_watch_api_path -5)" "${SCRIPT_DIR}"/*.jsonnet
}

# ES7
################################################################################
function ES7_put_json() {
  # args:
  # $1 URL to use when uploading
  es_upload_json_files "$1" "${SCRIPT_DIR}"/*.json
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
  es_upload_json_files "$(es_watch_api_path)" "${SCRIPT_DIR}"/*.jsonnet
}

function ES7_ILM_exec_jsonnet_and_upload_json() {
  es_upload_json_files '_ilm/policy' "${SCRIPT_DIR}"/*.jsonnet
}

function ES7_index-template_exec_jsonnet_and_upload_json() {
  json=$(execute_jsonnet -e "local generic_index_template = import '$1'; generic_index_template.get('$2', '$3')")
  url="_template/gitlab_pubsub_$2_inf_$3_template"
  echo "${url}"
  es_client "${url}" -X PUT --data-binary "${json}"
}

function ES7_set_cluster_settings() {
  url="_cluster/settings"
  get_json_and_jsonnet
  source "${array_file_path}"

  for json in "${json_array[@]}"; do
    es_client "${url}" -X PUT --data-binary "${json}"
  done
}
