# Container Registry database post-deployment migrations

## Context

Until recently the registry only had support for regular database schema migrations. After completing the GitLab.com registry upgrade/migration ([gitlab-org&5523](https://gitlab.com/groups/gitlab-org/-/epics/5523)), we're now in a position where the database has grown enough to make simple changes (like creating new indexes) take a long time to execute, so we had to introduce support for post-deployment migrations.

Regular schema migrations are automatically applied by the registry helm chart using a migrations job, introduced in [gitlab-org/charts/gitlab#2566](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2566). The mid/long-term goal is to have a similar automation for post-deployment migrations ([gitlab-org/charts/gitlab#3926](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3926)).

Meanwhile, we're already feeling the need to ship post-deployment migrations, so we had to move forward with a short-term solution. This implies skipping any post-deployment migrations during deployments and then raising a change request to have these manually applied from within a registry instance after deploying a version that includes new post-deployment migrations.

This document provides instructions for SREs to apply post-deployment migrations.

## Applying post-deployment migrations

This should be done from within a registry instance in K8s, using the built-in `registry` CLI. If needed, you can look at the relevant CLI documentation [here](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs-gitlab/database-migrations.md#administration).

1. Confirm that the registry version indicated in the Change Request matches the one (and there is only one) running in the target environment ([dashboard](https://dashboards.gitlab.net/d/registry-app/registry-application-detail?orgId=1&from=now-5m&to=now&viewPanel=3));

1. Connect to the target cluster for which maintenance is occurring ([runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-oncall-setup.md#kubernetes-api-access));

1. Find the oldest container registry Pod (ignore Pods that have `-migrations-` in the name!):

   ```sh
   kubectl get pods -n gitlab -l app=registry
   ```

1. Access the pod:

   ```sh
   kubectl exec -it <pod_name> -- sh
   ```

1. List pending migrations:

   ```sh
   registry database migrate status /etc/docker/registry/config.yml
   ```

   You should see something like this:

   ```text
   +---------------------------------------------------------------------------------+--------------------------------------+
   |                                    MIGRATION                                    |               APPLIED                |
   +---------------------------------------------------------------------------------+--------------------------------------+
   | 20210503145024_create_top_level_namespaces_table                                | 2022-11-29 14:12:58.477128 +0000 WET |
   | 20220803114849_update_gc_track_deleted_layers_trigger                           | 2022-11-29 14:13:00.209522 +0000 WET |
   | ...                                                                             | ...                                  |
   | 20221123174403_post_add_layers_simplified_usage_index_batch_1 (post deployment) |                                      |
   +---------------------------------------------------------------------------------+--------------------------------------+
   ```

   In this example, there is one pending post-deployment migration named `20221123174403_post_add_layers_simplified_usage_index_batch_1`. You know it's pending because `APPLIED` is empty. You know it's a post-deployment because of the `(post deployment)` suffix.

1. Confirm that there are no pending regular migrations in the list above;

1. Confirm that the number and name of pending post-deployment migrations matches those described in the change request;

1. Halt the execution if any of the above are false;

1. Proceed to apply post-deployment migrations:

   **Note:** If the registry team has identified (and mentioned in the change request description) that one or more of the pending migrations is expected to take more than 15 seconds to execute in a given environment (long-running), please proceed as described in [Applying long-running migrations](#instructions) instead. Continue to the next point here when done.

   ```sh
   registry database migrate up /etc/docker/registry/config.yml
   ```

   You should see something like this:

   ```text
   20221123174403_post_add_layers_simplified_usage_index_batch_1
   OK: applied 1 migrations
   ```

1. Wait for the above to complete and confirm there are no pending migrations:

   ```sh
   registry database migrate status /etc/docker/registry/config.yml
   ```

   You should see something like this:

   ```text
   +---------------------------------------------------------------------------------+--------------------------------------+
   |                                    MIGRATION                                    |               APPLIED                |
   +---------------------------------------------------------------------------------+--------------------------------------+
   | 20210503145024_create_top_level_namespaces_table                                | 2022-11-29 14:12:58.477128 +0000 WET |
   | 20220803114849_update_gc_track_deleted_layers_trigger                           | 2022-11-29 14:13:00.209522 +0000 WET |
   | ...                                                                             | ...                                  |
   | 20221123174403_post_add_layers_simplified_usage_index_batch_1 (post deployment) | 2022-12-14 12:31:57.42551 +0000 WET  |
   +---------------------------------------------------------------------------------+--------------------------------------+
   ```

   Note that `APPLIED` is no longer empty.

## Long-running migrations

### Applying

#### Why this is needed

If a post-deployment migration is expected to take close or more than 15 seconds to execute, then we will most likely run into a statement timeout when trying to do so when following the regular process.

Right now the registry can be configured with a single database server address, and that is used for PgBouncer's address. As done for Rails and the main database, when in need to disable or extend statement timeouts for long-running migrations, we need to:

1. Connect directly to the PosgtreSQL primary server, not through PgBouncer;
1. Use a single dedicated connection, not a connection pool.

Right now the registry has no support for the above two requirements. These are being addressed in [gitlab-org/container-registry#889](https://gitlab.com/gitlab-org/container-registry/-/issues/889) and [gitlab-org/charts/gitlab#3926](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3926), but until then, we need to use a workaround.

#### Instructions

Proceed as follows to apply pending migrations, if they include long-running ones:

1. Within the registry pod, make a temporary copy of the registry configuration file:

   ```sh
   cp /etc/docker/registry/config.yml /tmp/config.yaml
   ```

1. Determine the current PostgreSQL primary server, by using the following command in one of the registry database servers:

   ```sh
   ssh patroni-v12-registry-01-db-<env>.c.<project>.internal sudo gitlab-patronictl list
   ```

   Note that there is a small chance of having a primary rotation either due to failure or maintenance. If so, applying schema migrations will fail due to permission issues and the command above should be retried to obtain the new primary address. Confirm that the rotation was not due to a production incident first.

   See [this runbook](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/patroni-management.md#cluster-information) for more details about this command.

1. Modify the `database.host` and `database.port` attributes in the `/tmp/config.yaml` configuration file, so that it points to the primary server identified above. Additionally, set `database.pool.maxopen` to `1` and `database.pool.maxlifetime` to `1h`:

   ```yaml
   database:
      #...
      host: <hostname of primary server>
      port: <port of primary server>
      pool:
         maxopen: 1 # pool size
         maxlifetime: 1h # maximum amount of time a connection may be reused (up from 30m, for precaution)
   ```

1. Save the file

1. Apply pending migrations, providing the temporary configuration file as argument:

   ```sh
   registry database migrate up /tmp/config.yml
   ```

1. Continue as described in [Applying post-deployment migrations](#applying-post-deployment-migrations).

### Monitoring

The migrations tool used by the registry ([link](https://pkg.go.dev/github.com/rubenv/sql-migrate)) does not report when each individual migration has been applied, only when all pending are done (or one fails). As result, when applying multiple migrations, the registry CLI will output the list of all migrations to apply and wait for all to be applied (or for one to fail) before providing additional feedback (success or failure).

While the tool does not support realtime feedback, if applying multiple long-running migrations and wanting to know the progress of each one, we can use the `registry database migrate status /etc/docker/registry/config.yml` CLI command on another registry pod to see the list of migrations already applied.

Alternatively, we can look directly at the `schema_migrations` table (from where the `database migrate status` reads) on the registry database with the following query:

```sql
SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 10;
```

The output will look like follows:

```text
                              id                               |          applied_at
---------------------------------------------------------------+-------------------------------
 20221123174403_post_add_layers_simplified_usage_index_batch_1 | 2022-12-21 19:02:19.923828+00
 20220803114849_update_gc_track_deleted_layers_trigger         | 2022-08-17 16:34:14.045222+00
 20220803113926_update_gc_track_deleted_layers_function        | 2022-08-15 14:53:07.993973+00
 20220729143447_update_gc_review_after_function                | 2022-08-09 13:37:47.226631+00
 20220620111144_add_ansible_collection_media_type              | 2022-06-22 17:49:01.662984+00
 20220617102308_add_helm_chart_meta_media_type                 | 2022-06-22 17:49:01.658352+00
 20220606145028_add_acme_rocket_media_type                     | 2022-06-07 19:25:09.988723+00
 20220603122714_add_additional_misc_media_types                | 2022-06-03 20:37:30.036057+00
 20220603111337_add_more_misc_media_types                      | 2022-06-03 20:37:30.033107+00
 20220602095432_add_gardener_landscaper_media_type             | 2022-06-03 20:37:30.027821+00
(10 rows)
```

As each migration is applied, it will be inserted in this table, with the current time set in `applied_at`. So we can glance at this query result when wondering how many have been already applied.

Follow [this guide](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/Teleport/Connect_to_Database_Console_via_Teleport.md#accessing-the-database-console-via-teleport) on how to connect to the registry database using `tsh`.
