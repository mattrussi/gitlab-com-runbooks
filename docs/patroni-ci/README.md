<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Patroni-ci Service

* [Service Overview](https://dashboards.gitlab.net/d/patroni-ci-main/patroni-ci-overview)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22patroni-ci%22%2C%20tier%3D%22db%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:Postgres"

## Logging

* [Postgres](https://log.gprd.gitlab.net/goto/d0f8993486c9007a69d85e3a08f1ea7c)
* [system](https://log.gprd.gitlab.net/goto/3669d551a595a3a5cf1e9318b74e6c22)

## Troubleshooting 

[Reference Architecture (OS Upgrade)](../patroni/os_upgrade_reference_architecture.md)

### Recovering from CI Patroni cluster lagging too much or becoming completely broken

**IMPORTANT:** This troubleshooting only applies before CI decomposition is finished (ie. `patroni-ci` is still just a standby replica of `patroni`), after `patroni-ci` is promoted as Writer this runbook is no longer valid.

#### Symptoms

We have several alerts that detect replication problems, but this Runbook should only be considered if these alerts are related with the `Standby Leader` of our `patroni-ci` cluster, otherwise please consider this incident as a [regular Replica lagging issue](https://gitlab.com/gitlab-com/runbooks/-/blob/202ea907ce949198cec1b0f901f11a8bfb3acadd/docs/patroni/postgres.md#replication-is-lagging-or-has-stopped);

Possible related alerts are:

- Alert that replication is stopped
- Alert that replication lag is over 2min (over 120m on archive and delayed
replica)
- Alert that replication lag is over 200MB

To check what node is the `Standby Leader` of our `patroni-ci` cluster execute `ssh patroni-ci-01-db-gprd.c.gitlab-production.internal "sudo gitlab-patronictl list"`

#### Possible checks

- Check for lag pile up (continuous lag increase without reducing) in the `patroni-ci` Standby Leader [lag in Thanos](https://thanos.gitlab.net/graph?g0.expr=pg_replication_lag%7Benv%3D%22gprd%22%2C%20type%3D%22patroni-ci%22%7D&g0.tab=0&g0.stacked=0&g0.range_input=2d&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)
- Check if the CI Standby Leader can't find WAL segments from WAL stream
   1. SSH into the Standby Leader of `patroni-ci` cluster
   2. Check the `/var/log/gitlab/postgresql/postgresql.csv` log file for errors like `FATAL,XX000,"could not receive data from WAL stream: ERROR: requested WAL segment ???????????? has already been removed"`
- [Search `patroni-ci` logs into Elastic](https://log.gprd.gitlab.net/goto/54b89750-da38-11ec-aade-19e9974a7229) for `FATAL` error and messages like `XX000` or `"could not receive data from WAL stream"`

#### Resolution

This procedure can recover from `patroni-ci` being broken but was designed as a
[rollback procedure in case CI decomposition failover
fails](https://gitlab.com/gitlab-org/gitlab/-/issues/361759).

This solution will not be applicable once CI decomposition is finished
and the CI cluster is diverged fully from Main.

Before we've finished CI decomposition the Patroni CI cluster is just another
set of replicas and is only used for `read-only` traffic by `gitlab-rails`.
This means it is quite simple to recover if the cluster becomes corrupted, too
lagged behind or otherwise unavailable. The solution is to just send all CI
`read-only` traffic to Main Patroni replicas. The quickest way to do this is
reconfigure all Patroni Main replicas to also present as
`ci-db-replica.service.consul`.

We have a sample MR at for what this would involve on Staging
https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/1865 . The
equivalent for production would just be to change `gstg` to `gprd` in all file
names. In case this MR is unavailable the diff is:

<details><summary>Diff for reconfiguring Patroni cluster to also present as ci-db-replica in Consul</summary>

```diff
diff --git a/roles/gstg-base-db-patroni-ci.json b/roles/gstg-base-db-patroni-ci.json
index 0bb77e15e..711fe39c6 100644
--- a/roles/gstg-base-db-patroni-ci.json
+++ b/roles/gstg-base-db-patroni-ci.json
@@ -38,7 +38,7 @@
       ],
       "psql_command": "gitlab-psql -h /var/opt/gitlab/pgbouncer",
       "consul": {
-        "service_name": "ci-db-replica",
+        "service_name": "recovering-ci-db-replica",
         "extra_checks": [
           {
             "http": "http://0.0.0.0:8009/replica",
diff --git a/roles/gstg-base-db-patroni-main.json b/roles/gstg-base-db-patroni-main.json
index 44a9d55db..a4154ebb8 100644
--- a/roles/gstg-base-db-patroni-main.json
+++ b/roles/gstg-base-db-patroni-main.json
@@ -4,6 +4,9 @@
   "json_class": "Chef::Role",
   "default_attributes": {
     "gitlab-pgbouncer": {
+      "consul": {
+        "additional_service_names": ["ci-db-replica"]
+      },
       "databases": {
         "gitlabhq_production": {
           "host": "127.0.0.1",
```

</details>

You will likely want to apply this as quickly as possible by running chef
directly on all the Patroni Main nodes. Once you've done this you will have to
do 1 minor cleanup on Patroni CI nodes, since the `gitlab-pgbouncer` cookbook
does not handle renaming `service_name` you will also need to delete
`/etc/consul/conf.d/ci-db-replica*.json` from the problematic CI Patroni nodes.

Once the CI Patroni cluster has fully recovered you can revert these
changes but you should do this in 2 MRs using the following steps:

1. Change `roles/gstg-base-db-patroni-ci.json`
   back to `service_name: ci-db-replica` . Then wait for chef to run on
   CI Patroni nodes and confirm they are correctly registering in consul
   under DNS `ci-db-replica.service.consul`
2. Remove `additional_service_names` from
   `roles/gstg-base-db-patroni-main.json` so that Main nodes stop registering
   in Consul for `ci-db-replica.service.consul`
3. Remove `/etc/consul/conf.d/recovering-ci-db-replica*.json` from CI Patroni
   nodes as this is no longer needed and Chef won't clean this up for you

<!-- END_MARKER -->

<!-- ## Summary -->

<!-- ## Architecture -->

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
