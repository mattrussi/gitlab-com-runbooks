# Deadtuples affecting query performance

**Table of Contents**

[TOC]

This can be one of the reasons of seeing this alert.

Currently reindexing operations are scheduled during the weekend, during these operations, deadtuples can accumlate to the point of affecting query performance.

To check if there's an ongoing reindexing operation:

```sql
gitlabhq_production=# select
  now(),
  now() - query_start as query_age,
  now() - xact_start as xact_age,
  pid,
  backend_type,
  state,
  client_addr,
  wait_event_type,
  wait_event,
  xact_start,
  query_start,
  state_change,
  query
from pg_stat_activity
where
  state != 'idle'
  and backend_type != 'autovacuum worker'
  and xact_start < now() - '60 seconds'::interval
order by xact_age desc nulls last
;

-[ RECORD 1 ]---+-------------------------------------------------------------------------------------------
now             | 2023-01-09 10:42:57.18834+00
query_age       | 04:43:31.823733
xact_age        | 04:43:31.823733
pid             | 1641690
backend_type    | client backend
state           | active
client_addr     | 127.0.0.1
wait_event_type |
wait_event      |
xact_start      | 2023-01-09 05:59:25.364607+00
query_start     | 2023-01-09 05:59:25.364607+00
state_change    | 2023-01-09 05:59:25.364608+00
query           | /*application:web,db_config_name:ci*/ REINDEX INDEX CONCURRENTLY "public"."ci_builds_pkey"
```

To cancel the redinex and resume deadtuple cleaning:

```sql
gitlabhq_production=# select pg_cancel_backend(1641690);
 pg_cancel_backend
-------------------
 t
(1 row)
```

You should see an immediate relief in the `gitlab_ci_queue_retrieval_duration_seconds_bucket`, [thanos link](https://thanos.gitlab.net/graph?g0.expr=histogram_quantile(%0A%20%200.950000%2C%0A%20%20sum%20by%20(env%2Cenvironment%2Ctier%2Cstage%2Cle)%20(%0A%20%20%20%20rate(gitlab_ci_queue_retrieval_duration_seconds_bucket%7Benvironment%3D%22gprd%22%2Cstage%3D%22cny%22%7D%5B5m%5D)%0A%20%20)%0A)%0A&g0.tab=0&g0.stacked=0&g0.range_input=6h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D).
