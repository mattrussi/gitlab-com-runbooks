#!/bin/bash
# A script that finds the Group and Stage associated
# with a given Sidekiq worker, using gitlab repos
#
# Usage: sidekiq_help.sh <SidekiqWorkerName>"
# E.g. : sidekiq_help.sh Ci::CreateDownstreamPipelineWorker

# Function to fetch and parse YAML for feature category lookup
get_feature_category() {
  local worker="$1"
  local urls=(
    "https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/workers/all_queues.yml"
    "https://gitlab.com/gitlab-org/gitlab/-/raw/master/ee/app/workers/all_queues.yml"
  )

  for url in "${urls[@]}"; do
    category=$(curl -s "$url" | awk -v worker="$worker" '$0 ~ ":worker_name: " worker {getline; print $2}' | tr -d ':')
    if [[ -n $category ]]; then
      echo "$category"
      return
    fi
  done
}

# Function to fetch and parse JSON for group and stage lookup
get_stage_group() {
  local category="$1"
  local json_url="https://gitlab.com/gitlab-com/runbooks/-/raw/master/services/stage-group-mapping.jsonnet"

  curl -s "$json_url" | jsonnet - | jq --arg category "$category" '. | to_entries[] | select(.value.feature_categories | index($category)) | {name: .value.name, stage: .value.stage}'
}

# Main script execution
if [[ -z $1 ]]; then
  echo "Usage: $0 <SidekiqWorkerName>"
  exit 1
fi

worker_name="$1"
feature_category=$(get_feature_category "$worker_name")

if [[ -z $feature_category ]]; then
  echo "Feature category not found for worker: $worker_name"
  exit 1
fi

echo "Feature Category: $feature_category"
echo "Group and Stage Information:"
get_stage_group "$feature_category"
