#!/bin/bash
# shellcheck disable=SC2089,SC2016,SC2155,SC2162,SC2029,SC2086,SC2090

set -e
set -o pipefail

if [[ $# -lt 2 ]]; then
  echo >&2 "usage: redis-cluster-reconfigure.sh env cluster shard_count node_per_shard_count"
  echo >&2 ""
  echo >&2 "  e.g. redis-cluster-reconfigure.sh gstg redis-cluster-ratelimiting 3 3"
  exit 65
  echo >&2 ""
fi

export gitlab_env=$1
export gitlab_redis_cluster=$2
export shard_count=${3:-3}
export node_per_shard_count=${4:-3}

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

run_failover_script() {
  export i=$1
  export j=$2
  export fqdn="${gitlab_redis_cluster}-shard-$i-$j-db-${gitlab_env}.c.${gitlab_project}.internal"

  echo "Failover $fqdn if it is a primary node"
  # run sleep in ssh to avoid
  ssh $fqdn sudo gitlab-redis-cluster-failover-if-primary; sleep 30

  echo "Restarting $fqdn node to apply config changes"
  ssh $fqdn sudo systemctl restart redis-server.service; sleep 30
}


for (( i=1; i<=shard_count; i++ )); do
  for (( j=1; j<=node_per_shard_count; j++ )); do
    printf -v formatted_shard_nbr "%02d" "$i"
    printf -v formatted_node_nbr "%02d" "$j"
    run_failover_script $formatted_shard_nbr $formatted_node_nbr
  done
done

