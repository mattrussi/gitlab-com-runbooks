# PostgreSQL VACUUM

## Intro

PostgreSQL maintains data consistency using a [Multiversion Concurrency Control (MVCC)](https://www.postgresql.org/docs/current/mvcc-intro.html).

>  This means that each SQL statement sees a snapshot of data (a database version) as it was some time ago, regardless of the current state of the underlying data. This prevents statements from viewing inconsistent data produced by concurrent transactions performing updates on the same data rows, providing transaction isolation for each database session. MVCC, by eschewing the locking methodologies of traditional database systems, minimizes lock contention in order to allow for reasonable performance in multiuser environments.

As a result of this method we have multiple side effects, some of them are:
- Different version of tuples need to be stored (for different transactions)
- Information about which transaction can and can't see a version of a tuple need to be stored
- No longer needed versions (bloat) must be removed from tables and indexes via [`VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html)
- Various implementation side effects like ID wraparound

## VACUUM command

[`VACUUM`](https://www.postgresql.org/docs/current/sql-vacuum.html) is the manual tool to garbage-collect and optionally analyze database objects.
It can be used for complete databases or just single tables.

The most important options are
- FULL
- FREEZE
- ANALYZE

## Automatic VACUUM

In general, it should not be necessary to run VACUUM manually.
To archive this PostgreSQL has a mechanism to execute [VACUUM automatically](https://www.postgresql.org/docs/current/runtime-config-autovacuum.html) when needed, as well as throttling it to reduce impact on production.

### Settings via Chef

The general settings are managed by Chef and can be found in the corresponding roles like [gprd-base-db-postgres.json](https://ops.gitlab.net/gitlab-com/gl-infra/chef-repo/-/blob/master/roles/gprd-base-db-postgres.json).

```ini
"autovacuum_analyze_scale_factor": "0.005",
"autovacuum_max_workers": "6",
"autovacuum_vacuum_cost_delay": "5ms",
"autovacuum_vacuum_cost_limit": 6000,
"autovacuum_vacuum_scale_factor": "0.005",
...
"log_autovacuum_min_duration": "0", 
```

## Other related runbook pages

- [Check the status of transaction wraparound Runbook](check_wraparound.md)
- [`pg_xid_wraparound` Saturation Alert](pg_xid_wraparound_alert.md)
- [`pg_txid_xmin_age` Saturation Alert](pg_xid_xmin_age_alert.md)

## Literature

- https://www.postgresql.org/docs/current/mvcc-intro.html
- https://www.postgresql.org/docs/current/sql-vacuum.html
- https://www.postgresql.org/docs/current/runtime-config-autovacuum.html
