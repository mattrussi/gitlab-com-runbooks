# Frontend (HAProxy) Logging
HAProxy logs are not indexed in Elastic due to the volume of content. You can
view logs for a single HAProxy VM by connecting and tailing local logs, but
that may not be ideal when trying to investigate a site wide issue.

## Google BigQuery
HAProxy logs are collected into a table that can be queried in BigQuery. This
can provide the ability to search for patterns and look for recurring errors,
etc.

### Finding the HAProxy Logs in BigQuery
* Log into the Google Cloud web console and search or navigate to `BigQuery` in
the appropriate project.
* In the `Explorer` on the left, you should open a `node` for your environment.
  This will most likely be called `gitlab-production` or `gitlab-staging`.
* You will see a `haproxy_logs` section you can expand and select the
  `haproxy_` table.

### Querying Logs in BigQuery
The `jsonPayload.message` field will most likely be a common item to look at
since this contains the HAProxy log messages. There are other fields to
examine that may provide insights such as the `tt` field. Here is an example
query that could show `tt` values:
```sql
SELECT
  *
FROM
  `gitlab-production.haproxy_logs.haproxy_20210928`
WHERE
  jsonPayload.tt is not null
LIMIT
  1000
```

BigQuery access is in alpha for gcloud command line access at this time.
