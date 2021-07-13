#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

if command -v jsonnet-tool; then
  # Our work here is done...
  exit
fi

cat <<-EOF
jsonnet-tool is not installed.

The easiest way to install jsonnet-tool is by running the following command:

\`go get -u gitlab.com/gitlab-com/gl-infra/jsonnet-tool\`
EOF
exit 1
