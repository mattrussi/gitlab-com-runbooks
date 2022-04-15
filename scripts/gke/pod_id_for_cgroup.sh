#!/bin/bash

set -o pipefail
set -o errexit

# This is the standard mountpoint for the cgroups v1 cpu controller on COS and Ubuntu.
CPU_CGROUP_MOUNTPOINT="/sys/fs/cgroup/cpu,cpuacct"

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

function pod_id_for_cpu_cgroup()
{
    local TARGET_CGROUP=$1
    assert_is_cpu_cgroup "$TARGET_CGROUP"
    for POD_ID in $( crictl pods --quiet )
    do
        local POD_CGROUP=$( parent_cgroup_for_pod_id "$POD_ID" )
        if [[ "$TARGET_CGROUP" =~ ^${POD_CGROUP} ]] ; then
            echo "$POD_ID"
            return
        fi
    done
    die "Could not find a matching pod id.  Does that cgroup belong to a resource outside of kubernetes?"
}

function parent_cgroup_for_pod_id()
{
    local POD_ID=$1
    crictl inspectp $POD_ID 2> /dev/null | grep 'cgroup_parent' | awk '{ print $2 }' | tr -d '",'
}

function assert_is_cpu_cgroup()
{
    local TARGET_CGROUP=$1
    assert_cpu_cgroup_mountpoint_exists
    [[ -n "$TARGET_CGROUP" ]] || die "Must specify a non-blank cgroup path."
    [[ -d "$CPU_CGROUP_MOUNTPOINT/$TARGET_CGROUP" ]] || die "Could not find CPU cgroup: $TARGET_CGROUP"
}

function assert_cpu_cgroup_mountpoint_exists()
{
    df --type cgroup "$CPU_CGROUP_MOUNTPOINT" >& /dev/null || die "Cannot find expected base mountpoint for cpu cgroups."
}

function die()
{
    echo "ERROR: $*" 1>&2
    exit 1
}

main "$@"
