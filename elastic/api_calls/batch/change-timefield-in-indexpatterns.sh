#!/bin/bash

set -eufo pipefail
IFS=$'\t\n'

curl_data_initialize() {
  cat <<EOF
{
    "_source": ["index-pattern.title"],
    "query": {
        "term": {
            "type": "index-pattern"
        }
    }
}
EOF
}


curl -sSL -H 'Content-Type: application/json' -X GET "${ES7_URL_WITH_CREDS}/.kibana/_search" -d "$(curl_data_initialize)" | jq
