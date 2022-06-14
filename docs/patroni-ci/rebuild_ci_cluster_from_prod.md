# Steps to Recreate/Rebuild the CI CLuster using a Snapshot from the Master cluster (instead of pg_basebackup)

The recreation of the CI Cluster is done entirely locally through TF and Ansible, therefore **DO NOT COMMIT ANY FILE CHANGES** into the config-mgmt repo.

Make sure that **there are no CI Read requests being made in the patroni-ci cluster**,  as this indicates that the cluster is being used

- Check the [CI Reads in CI cluster thanos query](https://thanos-query.ops.gitlab.net/graph?g0.expr=(sum(rate(pg_stat_user_tables_idx_tup_fetch%7Benv%3D%22gprd%22%2C%20relname%3D~%22(ci_.*%7Cexternal_pull_requests%7Ctaggings%7Ctags)%22%2Cinstance%3D~%22patroni-ci-.*%22%7D%5B1m%5D))%20by%20(relname%2C%20instance)%20%3E%201)%20and%20on(instance)%20pg_replication_is_replica%3D%3D1&g0.tab=0&g0.stacked=0&g0.range_input=6h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D)

## Pre-requisites

1. Terraform should be installed and configured;
1. Ansible should be installed and configured;
1. Download/clone the [ops.gitlab.net/gitlab-com/gl-infra/config-mgmt](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt) project into your workspace;
1. Download/clone the [gitlab.com/gitlab-com/gl-infra/db-migration](https://gitlab.com/gitlab-com/gl-infra/db-migration) project into your workspace;
1. Check that the inventory file for your desired environment exists in `db-migration/pg-replica-rebuild/inventory/` and it's up-to-date with the hosts you're targeting;
1. Run `cd db-migration/pg-replica-rebuild; ansible -i inventory/<file> all -m ping` and ensure that all nodes are reachable;

## Destroy the Standby Cluster

1. Change the `"node_count"` at `variables.tf` to `=0` for the `patroni-ci` and `patroni-zfs-ci` clusters:

    ```
        "patroni-ci"           = 0
        "patroni-zfs-ci"       = 0
    ```

2. Apply the TF change `tf apply` checking if only the `patroni-ci` and its related modules are the ones that will be removed.
3. Manually delete the nodes from Chef
    <details><summary>Knife node delete GSTG</summary>

    ```
    for i in `seq 7`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gstg.c.gitlab-staging-1.internal; done; done
    knife node delete -y patroni-zfs-ci-01-db-gstg.c.gitlab-staging-1.internal
    knife client delete -y patroni-zfs-ci-01-db-gstg.c.gitlab-staging-1.internal
    ```

    </details>
    <details><summary>Knife node delete GPRD</summary>

    ```
    for i in `seq 10`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gprd.c.gitlab-production.internal; done; done
    knife node delete -y patroni-zfs-ci-01-db-gprd.c.gitlab-production.internal
    knife client delete -y patroni-zfs-ci-01-db-gprd.c.gitlab-production.internal
    ```

    </details>

## Take a snapshot from the Writer node

1. Find which instance is the database cluster Backup Node

    - GSTG: `knife search 'roles:gstg-base-db-patroni-backup-replica AND roles:gstg-base-db-patroni-main' --id-only`
    - GPRD: `knife search 'roles:gprd-base-db-patroni-backup-replica AND roles:gprd-base-db-patroni-v12' --id-only`

1. Log in into the Backup Node and execute a gcs-snapshot:
    ```
    sudo su - gitlab-psql
    PATH="/usr/local/sbin:/usr/sbin/:/sbin:/usr/local/bin:/usr/bin:/bin:/snap/bin"
    /usr/local/bin/gcs-snapshot.sh
    ```

Note: _At the last update (2022/06/10) the Replication Backup nodes were_ :
- GSTG: patroni-06-db-gstg.c.gitlab-staging-1.internal
- GPRD: patroni-10-db-gprd.c.gitlab-production.internal

## Recover the Patroni CI Standby Cluster

1. Change Terraform environment
    - Add the following module at `main.tf`, but **DO NOT SIMPLY COPY/PASTE IT**, set the `--project` and `--filter` accordingly with the environment you are performing the restore
        ```
        module "gcp_database_snapshot" {
            source        = "matti/resource/shell"
            version       = "1.5.0"
            command       = "gcloud compute snapshots list --project [gitlab-staging-1|gitlab-production] --limit=1 --uri --sort-by=~creationTimestamp --filter=status~READY --filter=sourceDisk~patroni-[06-db-gstg|10-db-gprd]-data"
            trigger       = timestamp()
            fail_on_error = true
        }
            locals {
            gcp_database_snapshot = trimprefix(module.gcp_database_snapshot.stdout, "https://www.googleapis.com/compute/v1/")
        }
        ```
    - Add the following line into `patroni-ci` module at `main.tf`
        ```
            data_disk_snapshot     = local.gcp_database_snapshot
        ```
    - Change the `"node_count"` of patroni CI back to 7 at `variables.tf`,
        ```
            "patroni-ci"           = 7
        ```
1. Create all the Patroni CI node with: `tf apply`
1. Check the `patroni-ci-01-db` Serial port in GCP console to see if the instance is already intialized and if Chef have finished to run, for example:
   - GSTG: https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-ci-01-db-gstg/console?port=1&project=gitlab-staging-1
   - GPRD: https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-ci-01-db-gprd/console?port=1&project=gitlab-production
1. Check if `scope=<cluster_name>` and if `name=<hostname>` in the `/var/opt/gitlab/patroni/patroni.yml` file, this is an evidence that Chef have sucessfully executed on the node. For example in the `patroni-ci-01-db-gstg` node the content of the file should be the following:
    ```
    $ sudo head -3 /var/opt/gitlab/patroni/patroni.yml
    ---
    scope: gstg-patroni-ci
    name: patroni-ci-01-db-gstg.c.gitlab-staging-1.internal
    ```
1. If Chef failed, you might have to:
    - Manually delete the nodes from Chef
        <details><summary>Knife node delete GSTG</summary>

        ```
        for i in `seq 7`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gstg.c.gitlab-staging-1.internal; done; done
        ````

        </details>
        <details><summary>Knife node delete GPRD</summary>

        ```
        for i in `seq 10`; do for type in node client; do knife $type delete -y patroni-ci-$(printf '%02d' $i)-db-gprd.c.gitlab-production.internal; done; done
        ````

        </details>
    - Restart the VM instances through the GCP console

1. Initialize the cluster using the `db-migration/pg-replica-rebuild` Ansible playbook, by executing:
    ```
    $ cd <workspace>/db-migration/pg-replica-rebuild
    $ ansible-playbook -i inventory/gstg.yml rebuild-all.yml
    ```

1. Force run of Chef-Client in the nodes to let all configuration files in sync with repo
    <details><summary>Force run of Chef-Client in GSTG</summary>

    ```
    knife ssh -C 7 "role:gstg-base-db-patroni-ci" "sudo chef-client"
    ```

    </details>
    <details><summary>Force run of Chef-Client in GPRD</summary>

    ```
    knife ssh -C 10 "role:gprd-base-db-patroni-ci" "sudo chef-client"
    ```

    </details>

## Recover the Patroni ZFS CI cluster

The ZFS cluster nodes can't be rebuild through GCP snapshots, because the `/var/opt/gitlab` mount point is a ZFS filesystem instead of EXT4 used by other Patroni nodes, therefore it's necessary to use the default `pg_basebackup` process to recreate this cluster.

1. Change Terraform environment
    - Change the `"node_count"` of patroni ZFS CI back to 1 at `variables.tf`,
        ```
            "patroni-zfs-ci"       = 1
        ```
1. Create Patroni ZFS CI node with: `tf apply`
1. Check the `patroni-zfs-ci-01-db` Serial port in GCP console to see if the instance is already intialized and if Chef have finished to run, for example:
   - GSTG: https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-zfs-ci-01-db-gstg/console?port=1&project=gitlab-staging-1
   - GPRD: https://console.cloud.google.com/compute/instancesDetail/zones/us-east1-c/instances/patroni-zfs-ci-01-db-gprd/console?port=1&project=gitlab-production
1. Check if `scope=<cluster_name>` and if `name=<hostname>` in the `/var/opt/gitlab/patroni/patroni.yml` file, this is an evidence that Chef have sucessfully executed on the node. For example in the `patroni-zfs-ci-01-db-gstg` node the content of the file should be the following:
    ```
    $ sudo head -3 /var/opt/gitlab/patroni/patroni.yml
    ---
    scope: gstg-patroni-zfs-ci
    name: patroni-zfs-ci-01-db-gstg.c.gitlab-staging-1.internal
    ```
1. Start the Patroni Cluster
    - Execute: `sudo systemctl start patroni.service`
    - If you observe the `/var/log/gitlab/patroni/patroni.log` you should see the `INFO: waiting for standby_leader to bootstrap` message
1. Remove the Patroni Cluster from DCS
    - Execute: `sudo gitlab-patronictl remove <cluster_name>`
        - GSTG cluster name: gstg-patroni-zfs-ci
        - GPRD cluster name: gprd-patroni-zfs-ci
    - If you observe the `/var/log/gitlab/patroni/patroni.log` you should see the `INFO: bootstrap_standby_leader in progress` message
6. Check if `pg_basebackup` is running
    - Execute: `ps -ef | grep pg_basebackup`
    - If there is a `/usr/lib/postgresql/??/bin/pg_basebackup` process running then you will have to wait it for completeion (which can take dozens of hours)
7. After `pg_basebackup` is finished the replica should apply/stream pending WAL files from the primary/writer or its archive location (which can also take dozens of hours);
    - Check the logs at `/var/log/gitlab/postgresql/postgresql.csv` to see if there is progress in the WAL recovery;
    - If the instance can't find the archive logs you should have to modify the archive location in `/etc/wal-g.d/env/WALG_GS_PREFIX`
