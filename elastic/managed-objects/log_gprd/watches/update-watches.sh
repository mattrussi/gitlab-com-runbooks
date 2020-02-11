#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_LOG_GPRD_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

es_put_json "$(es_watch_api_path)" "${SCRIPT_DIR}"/*.json
ES7_watches_exec_jsonnet_and_upload_json
