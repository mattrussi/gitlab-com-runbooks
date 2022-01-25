# PostgreSQL VACUUM

## Intro

PostgreSQL maintains data consistency using a [Multiversion Concurrency Control (MVCC)](https://www.postgresql.org/docs/current/mvcc-intro.html).

>  This means that each SQL statement sees a snapshot of data (a database version) as it was some time ago, regardless of the current state of the underlying data. This prevents statements from viewing inconsistent data produced by concurrent transactions performing updates on the same data rows, providing transaction isolation for each database session. MVCC, by eschewing the locking methodologies of traditional database systems, minimizes lock contention in order to allow for reasonable performance in multiuser environments.

As a result of this method we have multiple side effects, some of them are:
- Different version of tuples need to be stored (for different transactions)
- Information about which transaction can and can't see a version of a tuple need to be stored
- No longer needed versions (bloat) must be removed from tables and indexes via [`VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html)
- Various implementation side effects like ID wraparound

### VACUUM command

[`VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html) is the manual tool to garbage-collect and optionally analyze database objects.
It can be used for complete databases or just single tables.

The most important options are
- FULL
- FREEZE
- ANALYZE

### Automatic VACUUM

In general, it should not be necessary to run VACUUM manually.
To archive this PostgreSQL has a mechanism to execute [VACUUM automatically](https://www.postgresql.org/docs/current/runtime-config-autovacuum.html) when needed, as well as throttling it to reduce impact on production.

## General cluster vide settings via Chef

The general settings of our PostgreSQL clusters are managed by Chef and can be found in the corresponding roles like [gprd-base-db-postgres.json](https://ops.gitlab.net/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base-db-postgres.json).

```ini
"autovacuum_analyze_scale_factor": "0.005",
"autovacuum_max_workers": "6",
"autovacuum_vacuum_cost_delay": "5ms",
"autovacuum_vacuum_cost_limit": 6000,
"autovacuum_vacuum_scale_factor": "0.005",
...
"log_autovacuum_min_duration": "0", 
```

## Per table settings

For some workloads custom settings can be beneficial.
Think for example of a very large table append only table, which by design does not produce dead tuple, but is expensive to fully scan.

<!---
    How do we handle per table settings?
-->

## Monitoring

<!---
    How do we monitor VACUUM?
-->
## Alerts

<!---
    What alerts do we have, hat should we?
-->

## Challenges

### Resource consumption by VACUUM - [Optimize PostgreSQL AUTOVACUUM - 2021](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/413#note_820480832)

> Currently, our AUTOVACUUM setup is really aggressive. During our peak times, we see present a percentage of CPU utilization and IO on the primary database. (links) The goal of this epic is reduce the resource consumption from autovacuum, and keep the database healthy executing the autovacuum routines on the off peak times.

> Currently, we are reaching the autovacuum_freeze_max_age threshold of 200000000 in less than 3 days on average. Having this configuration so low for our environment forces the execution of AUTOVACUUM TO PREVENT WRAPAROUND in less than 3 days.

### Bloat due too infrequent VACUUM

Beside the problem of resource consumption caused by auto AUTOVACUUM we also see negative effects by bloated tables and indexes.

## Strategies and solutions - [Optimize PostgreSQL AUTOVACUUM - 2021](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/413#note_820480832)


### Current State

Currently, our AUTOVACUUM setup is really aggressive. During our peak times, we see present a percentage of CPU utilization and IO on the primary database. (links)
The goal of this epic is reduce the resource consumption from autovacuum, and keep the database healthy executing the autovacuum routines on the off peak times.

Currently, we are reaching the `autovacuum_freeze_max_age` threshold of `200000000` in less than 3 days on average.

Having this configuration so low for our environment forces the execution of `AUTOVACUUM TO PREVENT WRAPAROUND` in less than 3 days. 

### Desired State

We would like to monitor and evaluate if we can optimize the process.

* change the autovacuum_freeze_max_age and monitor the impact: `Increase autovacuum_freeze_max_age from 200000000 to 400000000`

* After 2 weeks of analyzing the impact: `Increase autovacuum_freeze_max_age from 400000000 to 600000000`

* After 2 weeks of analyzing the impact: `Increase autovacuum_freeze_max_age from 600000000 to 800000000`

* After 2 weeks of analyzing the impact: `Increase autovacuum_freeze_max_age from 800000000 to 1000000000`
 
* change or monitoring to be more efficient

* create a "mechanism"( I am thinking even a CI pipeline) to execute VACUUM FREEZE when the database is idle of the tables that are 80% or 90% of start the AUTOVACUUM WRAPAROUND.

### Major upgrade to PostgreSQL 13

The bencharked in [Benchmark of VACUUM PostgreSQL 12 vs. 13 (btree deduplication)](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/14723#note_761320190) hints us that btree deduplication, introduced in PostgreSQL 13, can help with multiple problems at once.

- Index size
- Index performance
- VACUUM resource consumption

n_dead_tup = 1000000

| vacuum phase | PG12 <br> (current version) | PG13 <br> (before reindex) | PG13 <br> (with btree deduplication) | PG13 - parallel vacuum <br> (2 parallel workers) |
| ------ | ------ | ------ | ------ | ------ |
| scanning heap | 4 min x sec | 4 min 18 sec | 4 min 51 sec | 4 min 16 sec |
| vacuuming indexes | 13 min x sec |13 min 5 sec | 10 in 46 sec | 3 min 20 sec |
| vacuuming heap | 1 min | 52 sec | 54 sec | 46 sec |
| total vacuum time | 18 min x sec | 18 min 16 sec | 16 min 31 sec | 8 min 24 sec |

## Incidents and issues involving VACUUM

- [Review Autovacuum Strategy for all high traffic tables](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/14811)
- [Optimize PostgreSQL AUTOVACUUM - 2021](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/413#note_820480832)
- [Lower autovacuuming settings for ci_job_artifacts table](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/14723)
- [Benchmark of different VACUUM settings](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/14723#note_758526535)
- [Benchmark of VACUUM PostgreSQL 12 vs. 13 (btree deduplication)](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/14723#note_761520231)

## Other related runbook pages

- [Check the status of transaction wraparound Runbook](check_wraparound.md)
- [`pg_xid_wraparound` Saturation Alert](pg_xid_wraparound_alert.md)
- [`pg_txid_xmin_age` Saturation Alert](pg_xid_xmin_age_alert.md)

## Literature

- https://www.postgresql.org/docs/current/mvcc-intro.html
- https://www.postgresql.org/docs/current/sql-vacuum.html
- https://www.postgresql.org/docs/current/runtime-config-autovacuum.html
