#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------
# This script will prepare your development environment
# while working on this project. Run it after cloning this
# project.
#
# It's recommended that you review
# https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md
# first.
# ---------------------------------------------------------

cd "$(dirname "${BASH_SOURCE[0]}")/.."

warn() {
  echo >&2 -e "${1-}"
  echo >&2 -e "Recommended reading: https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md"
}

if command -v rtx >/dev/null; then
  echo >&2 -e "rtx installed..."
elif [[ -n ${ASDF_DIR-} ]]; then
  warn "asdf installed, but deprecated. Consider switching over to rtx."
else
  warn "Neither rtx nor asdf is installed. "
  exit 1
fi

# install asdf dependencies
echo "installing asdf tooling with scripts/install-asdf-plugins.sh..."
./scripts/install-asdf-plugins.sh

# pre-commit is optional
if command -v pre-commit &>/dev/null; then
  echo "running pre-commit install..."
  pre-commit install
  pre-commit install-hooks
  pre-commit install --hook-type commit-msg
else
  warn "pre-commit is not installed. Skipping."
fi

# reshim just in case
asdf reshim

# Install jsonnet-bundler packages
./scripts/bundler.sh
