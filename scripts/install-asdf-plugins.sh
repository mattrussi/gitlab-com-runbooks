#!/usr/bin/env bash
# Vendored from https://gitlab.com/gitlab-com/gl-infra/common-template-copier
# Consider contributing upstream when updating this file

# This script will install the ASDF plugins required for this project

set -euo pipefail
IFS=$'\n\t'

# Temporary transition over to mise from asdf
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

setup_mise() {
  temp_MISE_SHORTHANDS_FILE=$(mktemp)
  trap 'do_mise_install' EXIT

  do_mise_install() {
    export MISE_SHORTHANDS_FILE=$temp_MISE_SHORTHANDS_FILE
    mise install -y || {
      # mise installs plugins in parallel, so order may lead to breaks when some plugins require others
      # the best workaround is to use `.mise.toml` with dependencies, but we can't do this until the
      # migration off asdf, in https://gitlab.com/gitlab-com/runbooks/-/issues/134 is complete.
      # until then, a retry without parallelism should be sufficient.

      # Export tool paths so that plugins can find dependencies
      eval "$(mise env --shell bash)"

      echo "mise install failed. Attempting a retry as it may be a plugin dependency issue" >&2
      MISE_JOBS=1 mise install -y
    }
    unset MISE_SHORTHANDS_FILE
    rm -f "$temp_MISE_SHORTHANDS_FILE"
  }

  install_plugin() {
    local plugin=$1
    local source=${2-}

    # No source? mise defaults should suffice.
    if [[ -z $source ]]; then return; fi

    # See https://mise.jdx.dev/configuration.html#mise-shorthands-file-config-mise-shorthands-toml
    echo "$plugin = \"$source\"" >>"$temp_MISE_SHORTHANDS_FILE"
  }

  remove_plugin_with_source() {
    local plugin=$1
    local source=$2

    if ! mise plugin list --urls | grep -qF "${source}"; then
      return
    fi

    echo "# Removing plugin ${plugin} installed from ${source}"
    mise plugin remove "${plugin}" || {
      echo "Failed to remove plugin: ${plugin}"
      exit 1
    } >&2
  }

  current() {
    mise current "$1" | awk '{print $2}'
  }
}

check_global_golang_install() {
  (
    pushd /
    current golang
    popd
  ) >/dev/null 2>/dev/null
}

# Do some validation to ensure that the environment is not misconfigured, as this may
# save a bunch of debugging effort down the line.

# Detect Rosetta 2
if [[ $(uname -m) == "arm64" ]] && [[ $(uname -p) == "x86_64" ]]; then
  echo "This shell is running in Rosetta emulating x86_64. Please use native mode Apple Silicon." >&2
  echo "For help visit https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md" >&2
  exit 1
fi

# Detect ancient versions of bash
if ((BASH_VERSINFO[0] < 4)); then
  echo "You're running bash < v4.0.0. Please upgrade to a newer version." >&2
  echo "For help visit https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md" >&2
  exit 1
fi

if command -v mise >/dev/null; then
  setup_mise
elif command -v rtx >/dev/null; then
  echo "rtx is no longer supported. Please upgrade from rtx to mise." >&2
  echo "For help visit https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md" >&2
  exit 1
elif [[ -n ${ASDF_DIR-} ]]; then
  if [[ -n ${CI-} ]]; then
    echo "asdf is deprecated about to be removed. It's time for you to switch over to mise." >&2
    echo "For help visit https://gitlab.com/gitlab-com/gl-infra/common-ci-tasks/-/blob/main/docs/developer-setup.md" >&2
    echo "If there is an issue blocking your move, please report it on https://gitlab.com/gitlab-com/runbooks/-/issues/134" >&2
    sleep 10
  fi

  setup_asdf
fi

# Install golang first as some of the other plugins require it.
install_plugin golang

# Jumping through these hoops does not seem necessary for mise, only asdf
if [[ -z ${CI:-} ]] && [[ -n ${ASDF_DIR-} ]]; then
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
install_plugin mimirtool https://github.com/asdf-community/asdf-mimirtool
