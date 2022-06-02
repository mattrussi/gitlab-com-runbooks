#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

REPO_DIR=$(
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  pwd
)

tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT

function render_readme_for_dir() {
  local dir=$1

  jsonnet-tool \
    -J "libsonnet" \
    -J "$dir/src" \
    -J "vendor" \
    render \
    "$dir/src/docs.jsonnet" \
    -m "${tmpdir}"

  awk -v readme_snippet="$tmpdir/README.snippet.md" '
    /^<!-- MARKER: do not edit this section directly. -->$/ {
      in_marker = 1;
      print;
      while ((getline line < readme_snippet) > 0)
        print line
      close(readme_snippet)
    }

    /^<!-- END_MARKER -->$/ {
      in_marker = 0;
    }

    // {
      if (in_marker != 1) { print }
    }' "$dir/README.md" >"$tmpdir/README.md.tmp"

  mv "$tmpdir/README.md.tmp" "$dir/README.md"
  echo "$dir/README.md"
}

for i in "${REPO_DIR}"/reference-architectures/*/src/docs.jsonnet; do
  dir=$(
    cd "$(dirname "$i")/.."
    pwd
  )

  render_readme_for_dir "$dir"
done
