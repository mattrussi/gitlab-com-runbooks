#!/bin/bash

set -eufo pipefail

export SCRIPTS_PATH
if [[ $(uname -s) = "Darwin" ]]; then
  SCRIPTS_PATH=$(dirname "$(readlink "$0")")
else
  SCRIPTS_PATH=$(dirname "$(readlink -f "$0")")
fi

wait_for_input() {
  if [[ "$NON_INTERACTIVE" = 'true' ]]; then
    echo
    return
  fi

  echo
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
  echo
}

change_issue_id=6287
chef_repo_mr_id=1308
env=gstg
google_project=gitlab-staging-1
redis_cluster=redis-ratelimiting

change_issue_url="https://gitlab.com/gitlab-com/gl-infra/production/-/issues/${change_issue_id}"
chef_repo_mr_url="https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/${chef_repo_mr_id}"
gitlab_production_project="gitlab-com%2Fgl-infra%2Fproduction"
gitlab_chef_repo_project="gitlab-com%2Fgl-infra%2Fchef-repo"

# curl --fail --silent --show-error \
#   --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
#   -XPUT \
#   https://gitlab.com/api/v4/projects/${gitlab_production_project}/issues/${change_issue_id}?add_labels=change::in-progress \
#   >/dev/null

label_exists="$(
  curl --fail --silent --show-error \
    --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
    https://gitlab.com/api/v4/projects/${gitlab_production_project}/issues/${change_issue_id} \
      | jq '.labels|select(. == "change::in-progress")'
)"

if [[ ! -n "$label_exists" ]]; then
  echo "error: in-progress label missing from change issue"
  exit 1
fi

# TODO: merge chef-repo MR

parallel --tag -k ssh $redis_cluster-{}-db-$gstg.c.$google_project.internal 'sudo gitlab-redis-cli info | grep ^redis_version' ::: 01 02 03

# $SCRIPTS_PATH/redis-reconfigure.sh $gstg $redis_cluster

# parallel --tag ssh $redis_cluster-{}-db-$gstg.c.$google_project.internal 'sudo gitlab-redis-cli info | grep ^redis_version' ::: 01 02 03
