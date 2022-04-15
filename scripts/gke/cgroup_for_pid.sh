#!/bin/bash

set -o pipefail
set -o errexit

function main()
{
    local TARGET_PID=$1
    [[ $1 =~ ^-h|--help$ ]] && usage
    [[ $# -eq 1 ]] || usage "Wrong number of arguments"
    cgroup_path_for_pid "$TARGET_PID"
}

function usage()
{
    local ERROR_MESSAGE=$1
    [[ -n "$ERROR_MESSAGE" ]] && echo "Error: $ERROR_MESSAGE" && echo

    cat <<HERE
Usage: cgroup_for_pid.sh [pid]

Finds the cpu cgroup path of the given PID.
This cgroup path uniquely identifies the cgroup and the discrete set of processes it includes.
Each container and pod typically has its own cgroup.
The cgroup path can be used as a group identified, for example to find and profile all member processes.
HERE
    exit 1
}

function cgroup_path_for_pid()
{
    local TARGET_PID=$1
    assert_is_pid "$TARGET_PID"
    local CPU_CGROUP=$( awk -F':' '$2 == "cpu,cpuacct" { print $3 }' "/proc/$TARGET_PID/cgroup" )
    [[ -n "$CPU_CGROUP" ]] || die "Could not find the CPU cgroup for PID $TARGET_PID"
    echo "$CPU_CGROUP"
}

function assert_is_pid()
{
    local TARGET_PID=$1
    [[ "$TARGET_PID" =~ ^[0-9,]+$ ]] || die "Invalid PID: '$TARGET_PID'"
    [[ -d "/proc/$TARGET_PID" ]] || die "PID $TARGET_PID does not exist in this PID namespace"
}

function die()
{
    echo "ERROR: $*" 1>&2
    exit 1
}

main "$@"
