# Postgres wait events analisys 

**Table of Contents**

[[_TOC_]]

## Goals and methodologies
This runbook outlines the steps for conducting a drill-down performance analysis, at the node level, from high-level view at the whole workload to individual queries (individual query IDs), based on wait event sampling using [pg_wait_sampling](https://github.com/postgrespro/pg_wait_sampling).

The wait event centric approach is also known as:

- Active Session History in Oracle
- [Performance Insights in AWS RDS](https://aws.amazon.com/rds/performance-insights/)
- [Query Insights in GCP CloudSQL](https://cloud.google.com/sql/docs/postgres/using-query-insights) (where pg_wait_sampling is also available)

In those systems, this approach is often considered as the main one for workload performance analysis and troubleshooting.

The wait events analysis dashboard serves as a vital tool for database performance troubleshooting, making complex performance patterns accessible and actionable. While traditional monitoring might tell you that your database is running slowly, this dashboard helps pinpoint exactly why it's happening. By visualizing database load through the lens of wait events, it enables both database experts and application teams to:

- identify performance bottlenecks without needing to dive deep into database internals
- understand whether performance issues stem from CPU utilization, I/O operations, memory constraints, lock or lwlock contentions
- trace problematic wait events back to specific queries (identifying their `queryid` values)
- think of wait events as a queue at a busy restaurant - this dashboard shows you not just how long the line is, but why people are waiting (kitchen backup, seating limitations, or staff shortages) and which orders are causing the longest delays; this practical insight can help move from reactive firefighting to proactive performance management
- the ASH dashboard bridges the gap between observing performance problems and understanding their root causes, enabling faster and more accurate resolution of database performance issues

Originally, for each backend (session), Postgres exposes wait events in columns `wait_event_type` and `wait_event` in system view `pg_stat_activity` ([docs](https://www.postgresql.org/docs/current/monitoring-stats.html#WAIT-EVENT-TABLE)).

These events need to be sampled for analysis. With external sampling (e.g., dashboard involved Marginalia and pg_stat_activity sampling built in https://gitlab.com/gitlab-com/runbooks/-/merge_requests/3370), the frequency of sampling is not high, cannot exceed 1/sec, thus data is not precise. With pg_wait_sampling, the sampling is internal, with high frequency (default: 100/second, 10ms rate), which is then exported infrequently, but has much better coverage and precision of metrics, enabling wider spectrum of performance optimization and troubleshooting works.


## Dashboards to be used
1. [https://dashboards.gitlab.net/d/postgres-ai-NEW_postgres_ai_04](Postgres Wait sampling dashboard)

Additionally, for further steps:
1. [Postgres aggregated query performance analysis](https://dashboards.gitlab.net/d/edxi03vbar9q8a/2d8e2a76-e4a8-5343-9709-18eadb0fa1a2?orgId=1) // TODO: update link to a permanent one
1. [Postgres single query performance analysis](https://dashboards.gitlab.net/d/de1633b2zd3wge/4482c6d0-58c5-5473-8cb1-bdf2f09c7757)  // TODO: update link to a permanent one; do not forget to update these links used below in text as well!!

## Analysis steps
### Step 1. Node wait evens (ASH) overview, all wait events are visible and not filtered out

### Step 2. Filter by wait event type. Events of given type are without query ids

### Step 3. Find query ids contributing to given wait type end event    


