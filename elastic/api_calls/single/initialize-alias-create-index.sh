#!/bin/bash
# Usage:
# 1) Find credentials to the relevant cluster in 1password
# 2) source these credentials, e.g.
# ```
# $ cat secret
# export ES7_URL_WITH_CREDS=https://elastic:supersecretpassword@123456asdfelastic.us-central1.gcp.cloud.es.io:9243
# $ source secret
# ```
# 3) run the script, e.g. `./initialize-alias-create-index.sh puma gstg`

set -eufo pipefail
IFS=$'\t\n'
index=$1
env=$2

curl_data_initialize() {
  cat <<EOF
{
    "aliases":
        {
            "pubsub-${index}-inf-${env}":
                {
                    "is_write_index": true
                }
        }

}
EOF
}

# initialize alias and create the first index
curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/pubsub-${index}-inf-${env}-000001" -d "$(curl_data_initialize)"
