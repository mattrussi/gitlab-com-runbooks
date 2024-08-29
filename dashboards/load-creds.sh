#!/usr/bin/env bash

set -euo pipefail
shopt -s inherit_errexit || true # Not all bash shells have this

if [ -z "$(which op)" ]; then
  echo "This script requires the 1Password CLI tool (op) - please install it from https://1password.com/downloads/command-line" >&2
  exit 1
fi

echo "Signing into 1Passsword..." >&2
op signin

echo "Retrieving grafana API token from 1password..." >&2
api_token=$(op read "op://Engineering/Grafana playground API token/Tokens/developer-playground-key API Key")

echo "Exporting GRAFANA_API_TOKEN..." >&2
export GRAFANA_API_TOKEN="${api_token}"
