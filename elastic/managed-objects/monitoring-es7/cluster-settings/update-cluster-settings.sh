#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
export ES_URL=$ES_MONITORING_ES7_URL
source "${SCRIPT_DIR}"/../../lib/update-scripts-functions.sh

# Here we need to check for oidc.libjsonnet, if it doesnt exist then we should create a dummy
# file so stuff keeps working; We use the extension *.libjsonnet instead of .json because of the
# catchall in elastic/managed-objects/lib/update-scripts-functions.sh
if [[ ! -v ES_MONITORING_ES7_OIDC ]]; then
  # Not set, just create a dummy file for now
  cat << EOF > oidc.libjsonnet
{
  "google": {
    "client_id": "some_id",
    "client_secret": "some_secret",
  }
}
EOF
else
  # If this envvar is set, then we'll use the file at this path as the oidc
  # configuration
  cp "${ES_MONITORING_ES7_OIDC}" oidc.libjsonnet
fi

ES7_set_cluster_settings
