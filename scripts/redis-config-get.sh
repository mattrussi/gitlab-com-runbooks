#!/bin/bash

set -euo pipefail

if [[ $# -ne 3 ]]; then
  >&2 echo "usage: redis-config-get.sh env cluster key"
  >&2 echo ""
  >&2 echo "  e.g. redis-config-get.sh gstg redis-cache io-threads"
  >&2 echo ""
  exit 65
fi

export gitlab_env=$1
export gitlab_redis_cluster=$2
export redis_config_key=$3

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
  >&2 echo "error: unknown environment: $gitlab_env"
  exit 1
  ;;
esac

export redis_cli='REDISCLI_AUTH="$(sudo grep ^requirepass /var/opt/gitlab/redis/redis.conf|cut -d" " -f2|tr -d \")" /opt/gitlab/embedded/bin/redis-cli'

export i=01
export fqdn="${gitlab_redis_cluster}-$i-db-${gitlab_env}.c.${gitlab_project}.internal"
ssh $fqdn "$redis_cli config get $redis_config_key"

export i=02
export fqdn="${gitlab_redis_cluster}-$i-db-${gitlab_env}.c.${gitlab_project}.internal"
ssh $fqdn "$redis_cli config get $redis_config_key"

export i=03
export fqdn="${gitlab_redis_cluster}-$i-db-${gitlab_env}.c.${gitlab_project}.internal"
ssh $fqdn "$redis_cli config get $redis_config_key"
