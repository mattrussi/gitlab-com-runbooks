#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

find_tests() {
  find "$REPO_DIR" -name '*_test.jsonnet' -not -path "$REPO_DIR/vendor/*"
}

find_tests | while read -r line; do
  echo "# ${line}"
  if ! jsonnet -J "$REPO_DIR/libsonnet" -J "$REPO_DIR/vendor" --ext-str "dashboardPath=test_file" "$line"; then
    echo "# ${line} failed"
    echo "# Retry with \`jsonnet -J \"$REPO_DIR/libsonnet\" -J \"$REPO_DIR/vendor\" --ext-str \"dashboardPath=test_file\" \"$line\"\`"
    exit 1
  fi
done
