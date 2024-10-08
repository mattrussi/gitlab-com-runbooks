#!/bin/bash

#
# Used to examine bootstrap logs from a single day and calculate the total duration
# including any reboots that may have occured between bootstrap script executions.
#
# This can be run against a remote machine by providing it's hostname as a single arg
# or on the machine directly by running without any arguments.
#
# It defaults to the current date, but can be overridden by setting a DATE_OVERRIDE var
# in the format of DATE_OVERRIDE=YYYYMMDD
#

set -eo pipefail

host="$1"

date="$(date "+%F" | tr -d '-')"

if [[ -n $DATE_OVERRIDE ]]; then
  date="$DATE_OVERRIDE"
fi

if [[ -n $host ]]; then
  # Determine if the remote script is already in place
  remote_script_exists=$(ssh -o StrictHostKeyChecking=no "$host" 'if [[ -f /tmp/find-bootstrap.sh ]]; then echo "exists"; else echo "not-exists"; fi' 2>/dev/null)
  # If the remote script exists, remove it
  if [[ $remote_script_exists == "exists" ]]; then
    ssh -o StrictHostKeyChecking=no "$host" 'sudo rm -f /tmp/find-bootstrap.sh'
  fi
  scp -o StrictHostKeyChecking=no -q "$0" "$host:/tmp/find-bootstrap.sh"
  ssh -o StrictHostKeyChecking=no "$host" "DATE_OVERRIDE=$DATE_OVERRIDE bash /tmp/find-bootstrap.sh"
  ssh -o StrictHostKeyChecking=no "$host" 'sudo rm -f /tmp/find-bootstrap.sh'
  exit 0
fi

file_prefix="/var/tmp/bootstrap-$date"

start_date="$(grep -h 'Bootstrap start' "$file_prefix"* | grep -v echo | head -n1 | sed 's/: Bootstrap start//')"
start_seconds="$(date --date="$start_date" "+%s")"

end_date="$(grep -h 'Bootstrap finished' "$file_prefix"* | grep -v echo | tail -n1 | sed 's/: Bootstrap finished.*//')"
end_seconds="$(date --date="$end_date" "+%s")"

chef_durations="$(grep 'Chef Client finished' "$file_prefix"* | awk -F'in ' '{print $2}' | awk '{print $1":"$3}')"
chef_seconds=0
chef_minutes=0

for duration in $chef_durations; do
  seconds="$(awk -F':' '{print $2}' <<<"$duration")"

  if [[ -z $seconds ]]; then
    seconds="$(awk -F':' '{print $1}' <<<"$duration")"
    chef_seconds=$((chef_seconds + 10#$seconds))
    continue
  fi

  minutes="$(awk -F':' '{print $1}' <<<"$duration")"
  chef_seconds=$((chef_seconds + 10#$seconds))
  chef_minutes=$((chef_minutes + 10#$minutes))
done

chef_seconds=$((chef_seconds + chef_minutes * 60))

echo "$HOSTNAME: Bootstrap duration: total: $((end_seconds - start_seconds))s, Chef: ${chef_seconds}s at $(date --date="$end_date" "+%Y-%m-%d %T")"
