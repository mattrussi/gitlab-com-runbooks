#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "${ASDF_DIR}/asdf.sh"

# shellcheck source=install-asdf-plugins.sh
"${SCRIPT_DIR}/install-asdf-plugins.sh"

# shellcheck source=update-asdf-version-variables
"${SCRIPT_DIR}/update-asdf-version-variables"

git diff --exit-code
