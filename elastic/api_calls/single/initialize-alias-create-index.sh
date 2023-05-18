#!/bin/bash
# Usage:
# 1) Find credentials to the relevant cluster in 1password
#   - Production: 'ElasticCloud gitlab-logs-prod', copy ES7_URL_WITH_CREDS
#   - Staging: 'ElasticCloud gitlab-logs-nonprod', copy ES7_URL_WITH_CREDS
# 2) set the following env with the appropriate credential e.g.
# ```
# export ES7_URL_WITH_CREDS=<from 1pass above>
# ```
# 3) run the script, e.g. `./initialize-alias-create-index.sh puma gstg`

set -eufo pipefail
IFS=$'\t\n'
index=$1
env=$2
index_full="pubsub-${index}-inf-${env}"
curl_data_initialize() {
  cat <<EOF
{
    "aliases":
        {
            "$index_full":
                {
                    "is_write_index": true
                }
        }

}
EOF
}

# initialize alias and create the first index
echo "Initializing ${index_full}" 1>&2
curl -sSL -H 'Content-Type: application/json' -X PUT "${ES7_URL_WITH_CREDS}/${index_full}-000001" -d "$(curl_data_initialize)"
