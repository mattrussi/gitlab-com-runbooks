#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

GCP_PROJECT=gitlab-production
TABLE_NAME=workhorse_thanksgiving

set -x

function drop_pre_table() {
  bq --project "$GCP_PROJECT" \
    query \
    --nouse_legacy_sql "DROP TABLE gcp_perf_analysis.${TABLE_NAME}_pre" || true
}

drop_pre_table

for i in '2019/10/*' '2019/11/*' '2019/09/*'; do
  bq --project "$GCP_PROJECT" \
    load \
    --source_format=CSV \
    --field_delimiter "±" \
    --max_bad_records 100 \
    --noreplace \
    --ignore_unknown_values \
    gcp_perf_analysis.${TABLE_NAME}_pre \
    "gs://gitlab-gprd-logging-archive/workhorse/$i" \
    json:STRING
done

read -r -d '' query <<EOF || true
  CREATE OR REPLACE TABLE gcp_perf_analysis.${TABLE_NAME}
  PARTITION BY DATE(timestamp)
  AS
  SELECT
    PARSE_TIMESTAMP("%FT%H:%M:%E*SZ", JSON_EXTRACT_SCALAR(json, "$.timestamp")) as timestamp,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['hostname']") as hostname,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['duration_ms']") as duration_ms,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['correlation_id']") as correlation_id,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['method']") as method,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['remote_ip']") as remote_ip,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['uri']") as uri,
    JSON_EXTRACT_SCALAR(json, "$.jsonPayload['written_bytes']") as written_bytes,
    SAFE_CAST(JSON_EXTRACT_SCALAR(json, "$.jsonPayload['status']") as int64) as status
  FROM gcp_perf_analysis.${TABLE_NAME}_pre
EOF

bq --project "$GCP_PROJECT" \
  query \
  --nouse_legacy_sql "$query"
