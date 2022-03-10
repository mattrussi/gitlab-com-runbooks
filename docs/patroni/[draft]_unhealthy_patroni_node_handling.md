# Patroni 

## [DRAFT] Handling Unhealthy Patroni Replica

### Overview

This runbook goal is to guide you on the evaulation of one ore more unhealthy Patroni replica node that could be causing searious application response time impact, and the steps necessary to remove the unhealthy replica if necessary.

Use this runbook as a guidance on how to diangnose if the Replica is considered Unhealthy and how to safely remove a random node from the Patroni cluster, which is not the same process as scaling down the cluster (that only removes the last nodes of the cluster).

### Pre-requisite 

- Patroni
    This runbook assumes that you know what Patroni is, what and how we use it for and possible consequences that might come up if we do not approach this operation carefully. This is not to scare you away, but in the worst case: Patroni going down means we will lose our ability to preserve HA (High Availability) on Postgres. Postgres not being HA means if there is an issue with the primary node Postgres wouldn't be able to do a failover and GitLab would shut down to the world. Thus, this runbook assumes you know this ahead of time before you execute this runbook. 

- Chef
    You are also expected to know what Chef is, how we use it in production, what it manages and how we stop/start chef-client across our hosts.

- Terraform
    You are expected to know what Terraform is, how we use it and how we make change safely (`tf plan` first).  


### Scope

This runbook is intended only for one or more `read` replica node(s) of Patroni cluster. 

### Mental Model

There was an incident but you should not panic, take a deep breath before moving into the steps of this runbook.

Let's build a mental model of what all are at play before you remove a random node from the Patroni cluster. 

- We have several Patroni clusters up and running in production
- Some of the replica nodes are taking read requests and processing them, but one ore more could be facing issues
- The fact that we have a cluster, it means the cluster might decide to promote any replica to primary (can be the target replica node you are trying to remove)
- There is chef-client running regularly to enforce consistency
- The cluster size is Terraform'd and defined in its respective [environment repository](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/tree/master/environments)

What this means is that we need to be aware of and think of:

- Evaluate which replicas are unhealthy and if is necessary to add more replicas to handle the workload
- Prevent the target replica node from getting promoted to primary
- Stop chef-client so that any change we make to the replica node and patroni doesn't get overwritten
- Take the node out of loadbalancing to drain all connections and then take the replica node out of the cluster
- Safely shutdown and destroy the node
- Let Terraform replace the instance

## Diagnose

### PostgreSQL health


#### A - Replication Lagging


#### B - SQL Query Latency


--

### Check Resource Contention


#### A - Disk

- Metrics
- Look for Stuck I/O and Disk Failure in syslog


#### B - Memory

- Trashing/Swapping
- OOM Kill




## Pausing Workload in the Unhealty Patroni replica



### Preparation

- You should do this activity in a CR (thus, allowing you to practice all of it in staging first)
- Make sure the replica you are trying to remove is NOT the primary, by running `gitlab-patronictl list` on a patroni node
- Pull up the [Host Stats](https://dashboards.gitlab.net/d/bd2Kl9Imk) Grafana dashboard and switch to the target replica host to be removed. This will help you monitor the host.

### Step 1 - Stop chef-client

- On the replica node run: `sudo chef-client-disable "Removing patroni node: Ref issue prod#xyz"`

### Step 2 - Take the replicate node out of load balancing

 If clients are connecting to replicas by means of [service discovery](https://docs.gitlab.com/ee/administration/database_load_balancing.html#service-discovery) (as opposed to hard-coded list of hosts), you can remove a replica from the list of hosts used by the clients by tagging it as not suitable for failing over (`nofailover: true`) and load balancing (`noloadbalance: true`). (If clients are configured with `replica.patroni.service.consul. DNS record` look at [this legacy method](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/patroni-management.md#legacy-method-consul-maintenance))

- Add a tags section to /var/opt/gitlab/patroni/patroni.yml on the node:

    ```
    tags:
      nofailover: true
      noloadbalance: true
    ```
- sudo systemctl reload patroni
- Test the efficacy of that reload by checking for the node name in the list of replicas:

    ```
    dig @127.0.0.1 -p 8600 db-replica.service.consul. SRV
    ```

    If the name is absent, then the reload worked.


- Wait until all client connections are drained from the replica (it depends on the interval value set for the clients), use this command to track number of client connections:

    ```
    for c in /usr/local/bin/pgb-console*; do $c -c 'SHOW CLIENTS;' | grep gitlabhq_production | grep -v gitlab-monitor; done | wc -l
    ```

    It can take a few minutes until all connections are gone. If there are still a few connections on pgbouncers after 5m you can check if there are actually any active connections in the DB (should be 0 most of the time):

    ```
    gitlab-psql -qtc "SELECT count(*) FROM pg_stat_activity
    WHERE pid <> pg_backend_pid()
    AND datname = 'gitlabhq_production'
    AND state <> 'idle'
    AND usename <> 'gitlab-monitor'
    AND usename <> 'postgres_exporter';"
    ```

You can see an example of taking a node out of service in [this issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1061).

### Step 3 - Stop patroni service on the node

Now it is save to stop the patroni service on this node. This will also stop postgres and thus terminate all remaining db connections if there are still some. With the patroni service stopped, you should see this node vanish from the cluster after a while when you run `gitlab-patronictl list` on any of the other nodes. We have alerts that fire when patroni is deemed to be down. Since this is an intentional change - either silence the alarm in advance and/or give a heads up to the EOC.

### Step 4 - 


### Step 5 - 




## Removing an unhealty replica from the Patroni cluster

### Step 1 - 

### Step 2 - 

## Replacing the replica

### Step 1 - 

### Step 2 - 

## Automation Thoughts



## Reference

[Patroni Management Internal Doc](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/patroni-management.md). 