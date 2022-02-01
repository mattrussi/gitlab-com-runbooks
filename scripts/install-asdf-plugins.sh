#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

plugin_list=$(asdf plugin list || echo "")

install_plugin() {
  plugin=$1
  if ! echo "$plugin_list" | grep -q "${plugin}" >/dev/null; then
    echo "# Installing plugin" "$@"
    asdf plugin add "$@" || {
      echo "Failed to perform plugin installation: " "$@"
      exit 1
    }
  fi

  echo "# Installing ${plugin} version"
  asdf install "${plugin}" || {
    echo "Failed to perform version installation: ${plugin}"
    exit 1
  }
}

check_global_golang_install() {
  cd /
  asdf current golang >/dev/null 2>/dev/null
}

# Install golang first as some of the other plugins require it
install_plugin golang

if [[ -z "${CI:-}" ]]; then
  # The go-jsonnet plugin requires a global golang version to be configured
  # and will otherwise fail to install
  #
  # This check is not neccessary in CI
  GOLANG_VERSION=$(asdf current golang | awk '{print $2}')

  if ! check_global_golang_install; then
    cat <<-EOF
The go-jsonnet plugin requires a global golang version to be configured.
Suggestion: run this command to set this up: 'asdf global golang ${GOLANG_VERSION}'
Then rerun this command.

Note: you can undo this change after running this command by editing ~/.tool-versions
EOF
    exit 1
  fi
fi

install_plugin go-jsonnet
install_plugin jb
install_plugin shellcheck
install_plugin shfmt
install_plugin jsonnet-tool https://gitlab.com/gitlab-com/gl-infra/asdf-jsonnet-tool.git
install_plugin ruby
