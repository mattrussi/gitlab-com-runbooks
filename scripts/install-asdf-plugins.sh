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

# Install golang first as some of the other plugins require it
install_plugin golang
install_plugin go-jsonnet
install_plugin jb
install_plugin shellcheck
install_plugin shfmt
install_plugin jsonnet-tool https://gitlab.com/gitlab-com/gl-infra/asdf-jsonnet-tool.git
install_plugin ruby
