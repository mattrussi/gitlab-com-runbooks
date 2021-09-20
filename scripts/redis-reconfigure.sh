#!/bin/bash
# shellcheck disable=SC2089,SC2016,SC2155,SC2162,SC2029,SC2086,SC2090

# TODO: consider adding a dry-run mode

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo >&2 "usage: redis-reconfigure.sh env cluster"
  echo >&2 ""
  echo >&2 "  e.g. redis-reconfigure.sh gstg redis-cache"
  echo >&2 ""
  exit 65
fi

export gitlab_env=$1
export gitlab_redis_cluster=$2

case $gitlab_env in
  pre)
    export gitlab_project=gitlab-pre
    ;;
  gstg)
    export gitlab_project=gitlab-staging-1
    ;;
  gprd)
    export gitlab_project=gitlab-production
    ;;
  *)
    echo >&2 "error: unknown environment: $gitlab_env"
    exit 1
    ;;
esac

export redis_cli='REDISCLI_AUTH="$(sudo grep ^requirepass /var/opt/gitlab/redis/redis.conf|cut -d" " -f2|tr -d \")" /opt/gitlab/embedded/bin/redis-cli'

export hosts=$(seq -f "${gitlab_redis_cluster}-%02g-db-${gitlab_env}" 1 3)
if [[ "$gitlab_redis_cluster" = "redis-cache" ]]; then
  export sentinel="${gitlab_redis_cluster}-sentinel-01-db-${gitlab_env}.c.${gitlab_project}.internal"
else
  export sentinel="${gitlab_redis_cluster}-01-db-${gitlab_env}.c.${gitlab_project}.internal"
fi

wait_for_input() {
  declare input
  while read -n 1 -p "Continue (y/n): " input && [[ $input != "y" && $input != "n" ]]; do
    echo
  done
  if [[ $input != "y" ]]; then
    echo
    echo >&2 "error: aborting"
    exit 1
  fi
  echo
}

failover_if_master() {
  export i=$1
  export fqdn="${gitlab_redis_cluster}-$i-db-${gitlab_env}.c.${gitlab_project}.internal"

  echo "> failover_if_master $fqdn"
  ssh "$fqdn" "$redis_cli role | head -n1"

  # if role is master, perform failover
  if [[ "$(ssh "$fqdn" "$redis_cli role | head -n1")" = "master" ]]; then
    echo failing over
    wait_for_input
    ssh "$sentinel" "/opt/gitlab/embedded/bin/redis-cli -p 26379 sentinel failover ${gitlab_env}-${gitlab_redis_cluster}"
  fi

  # wait for master to step down and sync (expect "slave" [sic] and "connected")
  while ! [[ "$(ssh "$fqdn" "$redis_cli role" | head -n1)" = "slave" ]]; do
    echo waiting for stepdown
    sleep 30
  done
  while ! [[ "$(ssh "$fqdn" "$redis_cli --raw role" | tail -n +4 | head -n1)" = "connected" ]]; do
    echo waiting for sync
    sleep 30
  done

  # wait for sentinel to ack the master change
  while [[ "$(ssh "$sentinel" "/opt/gitlab/embedded/bin/redis-cli -p 26379 --raw sentinel master ${gitlab_env}-${gitlab_redis_cluster}" | grep -A1 ^ip$ | tail -n +2 | awk '{ print substr($0, length($0)-1) }')" = "$i" ]]; do
    echo waiting for sentinel
    sleep 1
  done

  echo "< failover_if_master $fqdn"
}

reconfigure() {
  export i=$1
  export fqdn="${gitlab_redis_cluster}-$i-db-${gitlab_env}.c.${gitlab_project}.internal"

  echo "> reconfigure $fqdn"

  # double check that we are dealing with a replica
  echo checking role
  ssh "$fqdn" "$redis_cli --no-raw role"

  if [[ "$(ssh "$fqdn" "$redis_cli role | head -n1")" = "master" ]]; then
    echo >&2 "error: expected $fqdn to be replica, but it was a master"
    exit 1
  fi

  if [[ "$(ssh "$fqdn" "$redis_cli --raw role" | tail -n +4 | head -n1)" != "connected" ]]; then
    echo >&2 "error: expected $fqdn to be in state connected"
    exit 1
  fi

  # check sentinel quorum
  echo sentinel ckquorum
  ssh "$sentinel" "hostname; /opt/gitlab/embedded/bin/redis-cli -p 26379 sentinel ckquorum ${gitlab_env}-${gitlab_redis_cluster}"

  if [[ "$(ssh "$sentinel" "/opt/gitlab/embedded/bin/redis-cli -p 26379 sentinel ckquorum ${gitlab_env}-${gitlab_redis_cluster}")" != "OK 3 usable Sentinels. Quorum and failover authorization can be reached" ]]; then
    echo >&2 "error: sentinel quorum to be ok"
    exit 1
  fi

  # run chef-client
  echo chef-client
  wait_for_input
  ssh "$fqdn" "sudo chef-client"

  # temporarily disable rdb saving to allow for fast restart
  echo config get save
  ssh "$fqdn" "$redis_cli config get save"

  echo config set save
  ssh "$fqdn" "$redis_cli config set save ''"

  # reconfigure
  # this _will_ restart processes
  echo gitlab-ctl reconfigure
  wait_for_input
  ssh "$fqdn" "sudo gitlab-ctl reconfigure"

  # wait for master to step down and sync (expect "slave" [sic] and "connected")
  while ! [[ "$(ssh "$fqdn" "$redis_cli role" | head -n1)" = "slave" ]]; do
    echo waiting for stepdown
    sleep 30
  done
  while ! [[ "$(ssh "$fqdn" "$redis_cli --raw role" | tail -n +4 | head -n1)" = "connected" ]]; do
    echo waiting for sync
    sleep 30
  done

  # ensure config change took effect
  echo config get save
  ssh "$fqdn" "$redis_cli config get save"

  # check sync status
  echo $hosts | xargs -n1 -I{} ssh "{}.c.${gitlab_project}.internal" 'hostname; '$redis_cli' role | head -n1; echo'

  # check sentinel status
  ssh "$sentinel" "hostname; /opt/gitlab/embedded/bin/redis-cli -p 26379 sentinel ckquorum ${gitlab_env}-${gitlab_redis_cluster}"

  echo "< reconfigure $fqdn"
}

failover_if_master 01
reconfigure 01
echo

failover_if_master 02
reconfigure 02
echo

failover_if_master 03
reconfigure 03
