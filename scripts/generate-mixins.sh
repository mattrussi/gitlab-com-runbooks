#!/usr/bin/env bash

if ! command -v mixtool >/dev/null; then
    cat <<-EOF
mixtool is not installed.

mixtool is currently not available through asdf, please install using:

\`go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main\`

For more information on mixins, consult the README.md
EOF
fi

for file in $(find mimir-rules -name "mixin.libsonnet" ! -path "*/vendor/*"); do
(
    cd $(dirname ${file})
    jb update
    mixtool generate all --output-alerts "alerts.yaml" --output-rules "rules.yaml" --directory "dashboards" mixin.libsonnet
)
done