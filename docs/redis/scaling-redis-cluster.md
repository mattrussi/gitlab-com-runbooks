# Scaling Redis Cluster

This document outlines the steps for scaling an existing Redis Cluster. Previous scaling Change Requests (CR) shows the operation in practice:

## Previous CRs for scaling `redis-cluster-ratelimiting`

- [Provision nodes for new shard in redis-cluste-ratelimiting](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18042)
- [Enable debug command](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18043) (If the cluster already doesn't have `debug` command enabled)
- [Migrate the keyslots](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18061)

## Setting up instances

This guide defines a few variables in `<>`, which are used in the scripts in this guide:

- `ENV`: `pre`, `gstg`, `gprd`
- `GCP_PROJECT`: `gitlab-production` or `gitlab-staging-1`
- `INSTANCE_TYPE`: `feature-flag`
- `SHARD_NUMBER`: sequential number of shard to be added e.g. in an existing cluster with 3 shards, this would be `04`

**Note:** To avoid mistakes in manually copy-pasting the variables in `<>` above during a provisioning session, it is recommended to prepare this doc with all the variables replaced beforehand.

Use them as environment variables in your local shell:

```
export ENV=<ENV>
export PROJECT=<GCP_PROJECT>
export DEPLOYMENT=redis-cluster-<INSTANCE_TYPE>
export SHARD_NUMBER=<SHARD_NUMBER>
```

### 1. Update Redis app user to deny execution of `debug` command

Redis clusters provisioned before April 2024, didn't have `debug` command enabled, so at first, we need to enable the `debug` command and add ACL for `rails` (or any other app user e.g. `registry`) user to deny `-debug` command for it.

Update `redis-cluster` gkms vault secrets to disable `debug` command for `rails` user, using these commands in the [`chef-repo`](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/tree/master):

```
./bin/gkms-vault-edit redis-cluster $ENV
```

Update the JSON payload to include `-debug` for `rails` user for the target redis cluster (There is a space between `-debug` and `<`):

```
    ...
    "rails on ~* &* +@all -debug ><RAILS_REDACTED>"
    ...
```

Complete json object, with modification:

```
{
  ...,
  "redis-cluster-<INSTANCE_TYPE>": {
    "redis_conf": {
      "masteruser": "replica",
      "masterauth": "<REPLICA_REDACTED>",
      "user": [
        "default off",
        "replica on ~* &* +@all ><REPLICA_REDACTED>",
        "console on ~* &* +@all ><CONSOLE_REDACTED>",
        "redis_exporter on +client +ping +info +config|get +cluster|info +slowlog +latency +memory +select +get +scan +xinfo +type +pfcount +strlen +llen +scard +zcard +hlen +xlen +eval allkeys ><EXPORTER_REDACTED>",
        "rails on ~* &* +@all -debug ><RAILS_REDACTED>"
      ]
    }
  }
}

```

This won't change anything yet, on the existing redis instances, as we would reconfigure the redis processes as mentioned later in this guide.

### 2. Create Chef role for new shard

Create chef role for the new redis shard, based on the chef roles of existing redis shards of the cluster. Also add `enable-debug-command` option to redis configuration in the base role, if not added already.

An example MR can be found [here](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/4789).

### 3. Provision VMs

Provision the VMs for new redis shard by incrementing `count` parameter to generic-stor/google terraform module of target redis cluster in the [config-mgmt project in the ops environment](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/). An example MR can be found [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/merge_requests/8474).

After the MR is merged and applied, check the VM state via:

```
gcloud compute instances list --project=$PROJECT | grep "$DEPLOYMENT-shard-$SHARD_NUMBER"
```

You need to wait for the initial chef-client run to complete.

One way to check is to tail the serial port output to check when the initial run is completed. An example:

```
gcloud compute --project=$PROJECT instances tail-serial-port-output $DEPLOYMENT-shard-$SHARD_NUMBER-01-db-$ENV --zone us-east1-{c/b/d}
```

Also ensure that instance was bootstrapped and configured successfully by checking if `startup-script` finished with exit status 0. If it is not zero then check the reason and fix it and restart the instance once to initialize journald properly.

```
gcloud compute --project=$PROJECT instances tail-serial-port-output $DEPLOYMENT-shard-$SHARD_NUMBER-01-db-$ENV --zone us-east1-{c/b/d} | grep 'startup-script exit status'
```

### 4. Add instances in new shard to the cluster

a. SSH into one of the previous instances:

```
ssh $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal
```

b. Run the following:

Note: here we are exporting these env vars in the shell within redis instance.

```
export ENV=<ENV>
export PROJECT=<GCP_PROJECT>
export DEPLOYMENT=redis-cluster-<INSTANCE_TYPE>
export SHARD_NUMBER=<SHARD_NUMBER>
```

c. Use the following command to connect the master-node to the cluster. Run this for per shard FQDN, where multiple shards are being added at once, like `$DEPLOYMENT-shard-<SHARD_NUMBER>-01-db-$ENV.c.$PROJECT.internal:6379`.

```
sudo gitlab-redis-cli --cluster add-node \
  $DEPLOYMENT-shard-$SHARD_NUMBER-01-db-$ENV.c.$PROJECT.internal:6379 \
  $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal:6379

```

Use the following command to connect the remaining nodes to the cluster.  Update `{02,03,..m}` where `m` is the number of instances per shard.

```
for i in {02,03}; do
  master_node_id="$(sudo gitlab-redis-cli cluster nodes | grep $DEPLOYMENT-shard-$SHARD_NUMBER-01-db-$ENV.c.$PROJECT.internal | awk '{ print $1 }')";
  sudo gitlab-redis-cli --cluster add-node \
    $DEPLOYMENT-shard-$SHARD_NUMBER-$i-db-$ENV.c.$PROJECT.internal:6379 \
    $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal:6379 \
    --cluster-slave --cluster-master-id master_node_id
    sleep 2
done
```

### 5. Validation

Check the status as following to verify that all expected master nodes are shown as FQDNs or IP addresses and `cluster_state` is `ok`, with all `16384` slots assigned:

```
$ sudo gitlab-redis-cli --cluster info $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal:6379

redis-cluster-ratelimiting-shard-01-01-db-gprd.c.gitlab-production.internal:6379 (9b0828e3...) -> 78366 keys | 4096 slots | 2 slaves.
10.217.21.7:6379 (2c302ea5...) -> 78191 keys | 4097 slots | 2 slaves.
10.217.21.13:6379 (bce578ef...) -> 78822 keys | 4095 slots | 2 slaves.
10.217.21.2:6379 (17e6b401...) -> 78288 keys | 4096 slots | 2 slaves.
[OK] 313667 keys in 4 masters.
19.14 keys per slot on average.


$ sudo gitlab-redis-cli cluster info | head -n7
cluster_state:ok
cluster_slots_assigned:16384
cluster_slots_ok:16384
cluster_slots_pfail:0
cluster_slots_fail:0
cluster_known_nodes:12
cluster_size:4
```

## Enable `debug` command on redis-cluster

As mentioned in the beginning, most of the existing redis clusters do not have `debug` command enabled, which is needed to fix the cluster state as part of troubleshooting broken cluster.

This step will enable the `debug` command by reconfiguring the existing redis processes. Previous CR [here](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18043).

Run this from chef-repo, to find the existing redis instances and reconfigure them via `redis-cluster-reconfigure.sh`, excluding new shard as it was configured already with `enable-debug-command` above during provisioning.

**Warning:** `enable-debug-command` config option must already be enabled for newly added nodes during the time of provisioning otherwise failover wouldn't work, which is required for reconfiguring the redis process. Failover requires atleast one keyslot to be present on the shard.

```
knife search -i 'roles:$ENV-base-db-$DEPLOYMENT' | sort -V | grep -v $SHARD_NUMBER > $DEPLOYMENT-nodes.txt

scripts/redis-cluster-reconfigure.sh $DEPLOYMENT-nodes.txt
```

## Scale out cluster by resharding redis keys

Until now, we just added redis instances for new shard to the cluster but they do not have any redis keys (keyslots) yet and hence they are not serving any user requests.

In this phase, we will migrate keyslots from previous redis shards to the new shard, for load balancing. Previous CR [here](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18061).

### 1. Check the current keyslot assignments

Get the existing keyslot assignments and node IDs of the master nodes in the cluster, to prepare the commands required for migrating the keyslots.

```
ssh $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal
sudo gitlab-redis-cli cluster slots
```

For example:

```
$ sudo gitlab-redis-cli cluster slots
1) 1) (integer) 0
   2) (integer) 5460
   3) 1) "redis-cluster-ratelimiting-shard-01-01-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "9b0828e3379a06dc5bb749a106ab2cad9e47e4e4"
      4) 1) "ip"
         2) "10.217.21.10"
   4) 1) "redis-cluster-ratelimiting-shard-01-03-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "f70faccea8b3dfc3ce4cdecfaa23b5dfb0ed06b8"
      4) 1) "ip"
         2) "10.217.21.5"
   5) 1) "redis-cluster-ratelimiting-shard-01-02-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "3627d1e0b5962218a29eb852716fb23e5cb71265"
      4) 1) "ip"
         2) "10.217.21.8"
2) 1) (integer) 5461
   2) (integer) 10922
   3) 1) "redis-cluster-ratelimiting-shard-02-01-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "f8341afd4e539c75b5e6cf88943eb35f538344dd"
      4) 1) "ip"
         2) "10.217.21.4"
   4) 1) "redis-cluster-ratelimiting-shard-02-03-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "26596f03e09366be568c6255e61656e30901d01c"
      4) 1) "ip"
         2) "10.217.21.6"
   5) 1) "redis-cluster-ratelimiting-shard-02-02-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "2c302ea5ecc0820ec10514bc8cac07716bce7519"
      4) 1) "ip"
         2) "10.217.21.7"
3) 1) (integer) 10923
   2) (integer) 16383
   3) 1) "redis-cluster-ratelimiting-shard-03-01-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "ac03fceecca6a616cdaf92aabba8ca5221ea3f7e"
      4) 1) "ip"
         2) "10.217.21.3"
   4) 1) "redis-cluster-ratelimiting-shard-03-02-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "17e6b40148760ca0e881e965d24653006c560990"
      4) 1) "ip"
         2) "10.217.21.2"
   5) 1) "redis-cluster-ratelimiting-shard-03-03-db-gprd.c.gitlab-production.internal"
      2) (integer) 6379
      3) "103734e0928dddaaa4dcf8651fddf4fc1b8bd506"
      4) 1) "ip"
         2) "10.217.21.9"
```

First level keys are

- (1) and (2) are keyslots ranges (from/to) assigned to a shard
- (3) is the current master for shard owning the keyslots, whereas (4) and (5) are current replicas in the shard

Second level keys are

- (1) is FQDN of the redis instance
- (2) is the port number of redis server
- **(3) is the node ID of the redis instance** and required in resharding commands
- (4) is IP address of redis instance

### 2. Calibrate the batch size for migration

At first, make a few migrations with incrementally increasing batch sizes controlled by `--cluster-pipeline` argument. This is to avoid bringing down the masters involved in migration by consuming too much CPU and/or memory.

```
ssh $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal

# Trial runs to move some keyslots with batch size 30 to get time taken and its impact on CPU/Memory utilization
time sudo gitlab-redis-cli --cluster reshard 127.0.0.1:6379 --cluster-from <FROM_MASTER_NODE_ID> --cluster-to <TO_MASTER_NODE_ID> --cluster-slots <KEYSLOTS_TO_MOVE> --cluster-pipeline <BATCH_SIZE> --cluster-yes
```

At the same time, keep an eye on CPU/Memory saturation and Apdex violation metrics in redis-cluster dashboard. Also, note the time taken for migration of keyslots to estimate required time for completing the migration. If there is no impact on resources and time taken by migration is not reasonable, then try by increasing the `<BATCH_SIZE` and `<KEYSLOTS_TO_MOVE>` to come to a workable number.

### 3. Migrate keys from existing shards to new shard

The end goal is to distribute the number of keyslots (16384) among all shards equally (With some rounding off). By default, we have 16384 keyslots in a given redis cluster and a cluster with 3 shards have distribution like following:

1. First shard: 0-5460
2. Second shard: 5461-10922
3. Third shard: 10923-16383

In this case, a new fourth shard will intake equal number of keyslots from all 3 existing shards, so 1365 keyslots from each (after round off).

Once `<BATCH_SIZE>` and `<KEYSLOTS_TO_MOVE>` have been determined, migrate the keyslots from each of existing shards to the new shard using:

```
ssh $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal
time sudo gitlab-redis-cli --cluster reshard 127.0.0.1:6379 --cluster-from <FROM_MASTER_NODE_ID> --cluster-to <TO_MASTER_NODE_ID> --cluster-slots <KEYSLOTS_TO_MOVE> --cluster-pipeline <BATCH_SIZE> --cluster-yes
```

Keep a check on CPU/Memory saturation and Apdex violation metrics in redis-cluster dashboard. If an impact becomes visible and migration needs to be stopped, the process can be killed (ctrl + c).

### 4. Troubleshooting

- If during migration, cluster configuration breaks for some reason (redis process died or migration halted manually), then subsequent migrations will fail due to broken cluster state. Run the cluster fix command as follows, to recover from this situation:

```
ssh $DEPLOYMENT-shard-01-01-db-$ENV.c.$PROJECT.internal
sudo gitlab-redis-cli --cluster fix 127.0.0.1:6379
```

- During and after migration, redis clients will receive `redirections` to contact the new owner of keyslots. These are not errors themselves as redis clients would update their internal mapping of `keyslot -> master` upon receiving redirection from server. The redirections will take time to taper off and will definitely be gone after a new deployment in the environment, as all pods will be rotated in that scenario and will start off with up-to-date keyslot mapping.

## Key metrics to observe

Below is a list of some of the key metrics to check for:

- Redis service error ratio e.g. [Dashboard link](https://dashboards.gitlab.net/d/redis-cluster-ratelimiting-main/redis-cluster-ratelimiting3a-overview?from=now-6h&orgId=1&to=now&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-shard=All&viewPanel=3422679610)
- Redis Cluster Slots Failed e.g. [Dashboard link](https://dashboards.gitlab.net/d/redis-cluster-ratelimiting-main/redis-cluster-ratelimiting3a-overview?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-shard=All&viewPanel=115&from=now-6h&to=now)
- Redirections for the clients e.g. [Dashboard link](https://dashboards.gitlab.net/d/redis-cluster-ratelimiting-main/redis-cluster-ratelimiting3a-overview?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-shard=All&viewPanel=117&from=now-6h&to=now)
