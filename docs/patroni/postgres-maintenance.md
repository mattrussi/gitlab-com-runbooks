## Postgres Maintenance

### Using `disallow_database_ddl_feature_flags` feature flag to prevent DDL operations before an upgrade

During database upgrades, DDL operations should be ceased during the maintenance window. DBREs need to turn off a large quantity of feature flags:

- partition_manager_sync_partitions
- execute_batched_migrations_on_schedule
- execute_background_migrations
- database_reindexing
- database_async_index_operations
- database_async_foreign_key_validation
- database_async_index_creation

Each of these flags, controls specific processes that can interfere during an upgrade, hence, needed to be disabled. As the list
of flags is quite extensive, and, each one needs to be manually disabled, a single feature flag called `disallow_database_ddl_feature_flags`
was added, to prevent DDL operations from happening in the database.

The `disallow_database_ddl_feature_flags` is responsible for controlling all other flags, giving better support during a maintenance window.

To prevent DDL operations during a Postgres maintenance, `disallow_database_ddl_feature_flags` can be enabled:

```shell
/chatops run feature set disallow_database_ddl_feature_flags true
```

After maintenance is over, the flag should be disabled; otherwise, some processes will not be resumed:

```shell
/chatops run feature set disallow_database_ddl_feature_flags false
```
