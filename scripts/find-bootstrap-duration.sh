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

if [[ -n "$DATE_OVERRIDE" ]]; then
  date="$DATE_OVERRIDE"
fi

if [[ -n "$host" ]]; then
  scp -q $0 "$host:/tmp/find-bootstrap.sh"
  ssh -o StrictHostKeyChecking=no "$host" "DATE_OVERRIDE=$DATE_OVERRIDE bash /tmp/find-bootstrap.sh"
  exit 0
fi

file_prefix="/var/tmp/bootstrap-$date"

start_date="$(grep 'Bootstrap start' $file_prefix* | grep -v echo | head -n1 | cut -f2- -d':' | sed 's/: Bootstrap start//')"
start_seconds="$(date --date="$start_date" "+%s")"

end_date="$(grep 'Bootstrap finished' $file_prefix* | grep -v echo | tail -n1 | cut -f2- -d':' | sed 's/: Bootstrap finished.*//')"
end_seconds="$(date --date="$end_date" "+%s")"

echo "$HOSTNAME: Bootstrap duration: $((end_seconds - start_seconds)) seconds at $end_date"
