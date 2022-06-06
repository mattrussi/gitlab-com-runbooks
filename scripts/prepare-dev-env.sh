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

# check that asdf is installed
[[ -n ${ASDF_DIR:-} ]] || {
  warn "asdf not installed. "
  exit 1
}

# install asdf dependencies
echo "installing asdf tooling with scripts/install-asdf-plugins.sh..."
./scripts/install-asdf-plugins.sh

# pre-commit is optional
if command -v pre-commit &>/dev/null; then
  echo "running pre-commit install..."
  pre-commit install
  pre-commit install-hooks
else
  warn "pre-commit is not installed. Skipping."
fi

# reshim just in case
asdf reshim

# Install jsonnet-bundler packages
./scripts/bundler.sh
