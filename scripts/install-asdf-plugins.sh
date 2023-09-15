#!/usr/bin/env bash

# This script will install the ASDF plugins required for this project

set -euo pipefail
IFS=$'\n\t'

# Temporary transition over to rtx from asdf
# see https://gitlab.com/gitlab-com/runbooks/-/issues/134
# for details
setup_asdf() {
  # shellcheck source=/dev/null
  source "$ASDF_DIR/asdf.sh"

  plugin_list=$(asdf plugin list || echo "")

  install_plugin() {
    local plugin=$1

    if ! echo "${plugin_list}" | grep -q "${plugin}"; then
      echo "# Installing plugin" "$@"
      asdf plugin add "$@" || {
        echo "Failed to install plugin:" "$@"
        exit 1
      } >&2
    fi

    echo "# Installing ${plugin} version"
    asdf install "${plugin}" || {
      echo "Failed to install plugin version: ${plugin}"
      exit 1
    } >&2

    # Use this plugin for the rest of the install-asdf-plugins.sh script...
    asdf shell "${plugin}" "$(asdf current "${plugin}" | awk '{print $2}')"
  }

  remove_plugin_with_source() {
    local plugin=$1
    local source=$2

    if ! asdf plugin list --urls | grep -qF "${source}"; then
      return
    fi

    echo "# Removing plugin ${plugin} installed from ${source}"
    asdf plugin remove "${plugin}" || {
      echo "Failed to remove plugin: ${plugin}"
      exit 1
    } >&2

    # Refresh list of installed plugins.
    plugin_list=$(asdf plugin list)
  }

  current() {
    asdf current "$1" | awk '{print $2}'
  }
}

setup_rtx() {
  temp_RTX_SHORTHANDS_FILE=$(mktemp)
  trap 'do_rtx_install' EXIT

  do_rtx_install() {
    cat "$temp_RTX_SHORTHANDS_FILE"
    RTX_SHORTHANDS_FILE=$temp_RTX_SHORTHANDS_FILE rtx install
    rm -f "$temp_RTX_SHORTHANDS_FILE"
  }

  install_plugin() {
    local plugin=$1
    local source=${2-}

    # No source? rtx defaults should suffice.
    if [[ -z $source ]]; then return; fi

    # See https://github.com/jdxcode/rtx#rtx_shorthands_fileconfigrtxshorthandstoml
    echo "$plugin = \"$source\"" >>"$temp_RTX_SHORTHANDS_FILE"
  }

  remove_plugin_with_source() {
    local plugin=$1
    local source=$2

    if ! rtx plugin list --urls | grep -qF "${source}"; then
      return
    fi

    echo "# Removing plugin ${plugin} installed from ${source}"
    rtx plugin remove "${plugin}" || {
      echo "Failed to remove plugin: ${plugin}"
      exit 1
    } >&2
  }

  current() {
    rtx current "$1" | awk '{print $2}'
  }

  check_global_golang_install() {
    (
      pushd /
      current golang
      popd
    ) >/dev/null 2>/dev/null
  }
}

if command -v rtx 2> /dev/null; then
  setup_rtx
elif [[ -n ${ASDF_DIR-} ]]; then
  setup_asdf
fi

# Install golang first as some of the other plugins require it.
install_plugin golang

# Jumping through these hoops does not seem necessary for rtx, only asdf
if [[ -z "${CI:-}" ]] && [[ -n ${ASDF_DIR-} ]]; then
  # The go-jsonnet plugin requires a global golang version to be configured
  # and will otherwise fail to install.
  #
  # This check is not necessary in CI.
  GOLANG_VERSION=$(current golang)

  if ! check_global_golang_install; then
    cat <<-EOF
---------------------------------------------------------------------------------------
The go-jsonnet plugin requires a global golang version to be configured.$
Suggestion: run this command to set this up: 'asdf global golang ${GOLANG_VERSION}'
Then rerun this command.

Note: you can undo this change after running this command by editing ~/.tool-versions
---------------------------------------------------------------------------------------
EOF
    exit 1
  fi
fi

install_plugin go-jsonnet
install_plugin jb
install_plugin shellcheck
install_plugin shfmt
install_plugin terraform
install_plugin promtool https://gitlab.com/gitlab-com/gl-infra/asdf-promtool.git
install_plugin thanos https://gitlab.com/gitlab-com/gl-infra/asdf-promtool.git
install_plugin amtool https://gitlab.com/gitlab-com/gl-infra/asdf-promtool.git
install_plugin jsonnet-tool https://gitlab.com/gitlab-com/gl-infra/asdf-gl-infra.git
install_plugin kubeconform https://github.com/lirlia/asdf-kubeconform.git
install_plugin ruby
install_plugin nodejs
install_plugin yq
install_plugin pre-commit
install_plugin python
