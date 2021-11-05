#!/usr/bin/env bash

set -eufo pipefail

if [[ $(uname -s) = "Darwin" ]]; then
  RUNBOOK_PATH=$(dirname "$(readlink "$0")")
else
  RUNBOOK_PATH=$(dirname "$(readlink -f "$0")")
fi

BIN_DIR="$RUNBOOK_PATH/bin/"
EXEC_PATH="$BIN_DIR$1"

if [[ ! -f "$EXEC_PATH" ]]; then
  echo >&2 "glsh: executable path not found: $EXEC_PATH "
  exit 1
fi

if [[ ! -x "$EXEC_PATH" ]]; then
  echo >&2 "glsh: File not executable run: chmod +x $EXEC_PATH"
  exit 1
fi

shift # Remove the first paramater so we can send the rest to the executable
exec "$EXEC_PATH" "$@"
