#!/bin/bash

set -eufo pipefail
IFS=$'\t\n'

#for index in "${indices[@]}"; do
#  curl -sSL -H 'Content-Type: application/json' -X POST "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}/_rollover" -d "$(curl_data_close_index)"
#done

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
