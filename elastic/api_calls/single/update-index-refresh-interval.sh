#!/bin/bash

# Update the refresh_interval time to what you want to set across ALL pubsub indices.
# Keep in mind, this only affects the current indices and will go away when they
# are rolled over.

set -eufo pipefail
IFS=$'\t\n'

curl_data() {
  cat <<EOF
{
  "index" : {
    "refresh_interval" : "10s"
  }
}
EOF
}

curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/pubsub-*/_settings" -d "$(curl_data)"
