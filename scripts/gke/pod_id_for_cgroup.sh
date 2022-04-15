#!/bin/bash

set -o pipefail
set -o errexit

source "$( dirname "$0" )/container_inspection_library.sh"

function main()
{
    TARGET_CGROUP=$1
    [[ $1 =~ ^-h|--help$ ]] && usage
    [[ $# -eq 1 ]] || usage "Wrong number of arguments"
    pod_id_for_cpu_cgroup "$TARGET_CGROUP"
}

function usage()
{
    local ERROR_MESSAGE=$1
    [[ -n "$ERROR_MESSAGE" ]] && echo "Error: $ERROR_MESSAGE" && echo

    cat <<'HERE'
Usage: pod_id_for_cgroup.sh [cgroup_path]

Given a cpu cgroup path (such as reported by /proc/[pid]/cgroup) for any container in the pod
(or the pod itself), find the corresponding pod id.

This pod id can be used with "crictl" subcommands such as:
  $ crictl ps --pod $POD_ID
  $ crictl inspectp $POD_ID

Note: This script relies on the "crictl" utility to query the configured container runtime API.
HERE
    exit 1
}

main "$@"
