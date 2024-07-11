#!/bin/bash

set -euo pipefail

IFS=$'\n\t'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "${SCRIPT_DIR}"

# Check if sufficient arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 {alerts|rules|dashboards|all} MIXIN_DIR"
    exit 1
fi

if ! command -v mixtool >/dev/null; then
  cat <<-EOF
mixtool is not installed.

Please install using:

\`go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main\`

For more information on mixins, consult the docs/monitoring/mixins.md readme in this repo.
EOF
  exit 1
fi

COMMAND=$1
MIXIN_DIR=$2

# Create necessary directories
OUTPUT_DIR="generated/$MIXIN_DIR"
mkdir -p "generated"
mkdir -p "$OUTPUT_DIR"

# Change to the specified MIXIN_DIR
cd "$MIXIN_DIR" || exit

jb update

# Common options for mixtool commands
COMMON_OPTS=("-J" "vendor" "-J" "vendor/gitlab.com/gitlab-com/runbooks/libsonnet")

# Execute the appropriate command
case $COMMAND in
    alerts)
        mixtool generate alerts "${COMMON_OPTS[@]}" \
            -a "../$OUTPUT_DIR/prometheus_alerts.yaml" \
            -y mixin.libsonnet
        ;;
    rules)
        mixtool generate rules "${COMMON_OPTS[@]}" \
            -r "../$OUTPUT_DIR/prometheus_rules.yaml" \
            -y mixin.libsonnet
        ;;
    dashboards)
        mixtool generate dashboards "${COMMON_OPTS[@]}" \
            -d "../$OUTPUT_DIR/dashboards" \
            mixin.libsonnet
        ;;
    all)
        mixtool generate all "${COMMON_OPTS[@]}" \
            -d "../$OUTPUT_DIR/dashboards" \
            -r "../$OUTPUT_DIR/prometheus_rules.yaml" \
            -a "../$OUTPUT_DIR/prometheus_alerts.yaml" \
            -y mixin.libsonnet
        ;;
    *)
        echo "Invalid command. Use one of: alerts, rules, dashboards, all."
        exit 1
        ;;
esac
