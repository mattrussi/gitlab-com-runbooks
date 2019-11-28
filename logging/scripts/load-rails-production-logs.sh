#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

GCP_PROJECT=gitlab-production
TABLE_NAME=loving_thanksgiving_like_a_turkey

for i in '2019/10/*' '2019/11/*' '2019/09/*'; do
  bq --project "$GCP_PROJECT" \
    load \
      --source_format=CSV \
      --field_delimiter "±" \
      --max_bad_records 100 \
      --noreplace \
      --ignore_unknown_values \
      gcp_perf_analysis.${TABLE_NAME}_pre \
      "gs://gitlab-gprd-logging-archive/rails.production/$i" \
      json:STRING
done

read -r -d '' query << EOF || true
  CREATE OR REPLACE TABLE \`gitlab-production.gcp_perf_analysis.${TABLE_NAME}\`
  PARTITION BY DATE(timestamp)
  AS
  SELECT
    PARSE_TIMESTAMP("%FT%H:%M:%E*SZ", JSON_EXTRACT_SCALAR(json, "$.timestamp")) as timestamp,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['path']") as path,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['controller']") as controller,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['action']") as action,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['format']") as format,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['method']") as method,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['status']") as status,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['username']") as username,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['remote_ip']") as remote_ip,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['duration']") as float64) as duration,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['db']") as float64) as db,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['view']") as float64) as view,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['queue_duration']") as float64) as queue_duration,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['gitaly_calls']") as INT64) as gitaly_calls,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['gitaly_duration']") as float64) as gitaly_duration
  FROM \`gitlab-production.gcp_perf_analysis.${TABLE_NAME}_pre\`
EOF

bq --project "$GCP_PROJECT" \
    query \
    --nouse_legacy_sql "$query"
