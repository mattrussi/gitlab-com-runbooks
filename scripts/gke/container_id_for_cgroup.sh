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
    container_id_for_cpu_cgroup "$TARGET_CGROUP"
}

function usage()
{
    local ERROR_MESSAGE=$1
    [[ -n "$ERROR_MESSAGE" ]] && echo "Error: $ERROR_MESSAGE" && echo

    cat <<HERE
Usage: container_id_for_cgroup.sh [cgroup_path]

Given a cpu cgroup path (such as reported by /proc/[pid]/cgroup), find the corresponding container id.
This container id can be used with "crictl" subcommands such as "ps" and "inspect".

Note: This script relies on the "crictl" utility to query the configured container runtime API.
HERE
    exit 1
}

function container_id_for_cpu_cgroup()
{
    local TARGET_CGROUP=$1
    assert_is_cpu_cgroup "$TARGET_CGROUP"
    for CONTAINER_ID in $( crictl ps --quiet )
    do
        local CONTAINER_CGROUP=$( cgroup_for_container_id "$CONTAINER_ID" )
        if [[ "$CONTAINER_CGROUP" == "$TARGET_CGROUP" ]] ; then
            echo "$CONTAINER_ID"
            return
        fi
    done
    die "Could not find a matching container id.  Does that cgroup belong to a pod or a non-kubernetes resource?"
}

function cgroup_for_container_id()
{
    local CONTAINER_ID=$1
    crictl inspect $CONTAINER_ID 2> /dev/null | grep 'cgroupsPath' | awk '{ print $2 }' | tr -d '",'
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
