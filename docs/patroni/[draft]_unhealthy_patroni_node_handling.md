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

## Chapter 1 - Diagnose

### PostgreSQL health


#### A - Replication Lagging

If just one or a few Replicas are lagging in relation with the Primary/Writer node there is a great chance that the issue is on the Replica side, so the first evidence of an unhealthy replica is replication lag.

- Execute `gitlab-patronictl list` to get the amount of Lag, in MBytes, for each Replica

For example the following output show aprox. 19 GB (19382 MB) of lag in the `patroni-08-db-gstg` host

```
# gitlab-patronictl list
+ Cluster: pg12-ha-cluster-stg (6951753467583460143) ------------+---------+---------+----+-----------+---------------------+
| Member                                         | Host          | Role    | State   | TL | Lag in MB | Tags                |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-01-db-gstg.c.gitlab-staging-1.internal | 10.224.29.101 | Leader  | running |  7 |           |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-02-db-gstg.c.gitlab-staging-1.internal | 10.224.29.102 | Replica | running |  7 |         3 |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-03-db-gstg.c.gitlab-staging-1.internal | 10.224.29.103 | Replica | running |  7 |         0 |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-04-db-gstg.c.gitlab-staging-1.internal | 10.224.29.104 | Replica | running |  7 |         0 |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-05-db-gstg.c.gitlab-staging-1.internal | 10.224.29.105 | Replica | running |  7 |         0 | nofailover: true    |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-06-db-gstg.c.gitlab-staging-1.internal | 10.224.29.106 | Replica | running |  7 |         3 | nofailover: true    |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-07-db-gstg.c.gitlab-staging-1.internal | 10.224.29.107 | Replica | running |  7 |         0 |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
| patroni-08-db-gstg.c.gitlab-staging-1.internal | 10.224.29.108 | Replica | running |  7 |     19382 |                     |
+------------------------------------------------+---------------+---------+---------+----+-----------+---------------------+
```

- Or you can look into the following Grafana Dashboard:

	- Lag time: https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1&viewPanel=16 
	- Lag size: https://dashboards.gitlab.net/d/000000144/postgresql-overview?orgId=1&viewPanel=11


#### B - SQL Query Latency


--

### Host health - Check Resource Contention


#### A - Disk

- Metrics
- Look for Stuck I/O and Disk Failure in syslog


#### B - Memory

- Trashing/Swapping
- OOM Kill




## Chapter 2 - Draining Workload from the Unhealty Patroni replica



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
- Reload Patroni
    ```
    sudo systemctl reload patroni
    ```
- Check that Patroni host now is no longer considered for failover nor loadbalance 
   ```
   sudo gitlab-patronictl list
   ```
 
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
    gitlab-psql -qc \
       "select count(*) from pg_stat_activity
        where backend_type = 'client backend'
        and state <> 'idle'
        and pid <> pg_backend_pid()
        and datname <> 'postgres'"
    ```

You can see an example of taking a node out of service in [this issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1061).
 
 
### Step 3 - Decide if you will remove the node or wait for it to recover

This is a critical decision because replacing a Patroni Replica can take up to <mark>reference to Mean-Time-To-Create instance</mark>. Also consider that creating/replacing a Replica will have significant I/O impact in the Primary/Writer node during the whole operation.

If you decide to relpace the unhealthy replica proceed to chapter 3.


## Chapter 3 - Removing an unhealty replica from the Patroni cluster


**IMPORTANT:** make sure that the connections that the workload is drained from the unhealthy replica (link to previous chapter)


### Step 1 - Stop patroni service on the node

Now it is save to stop the patroni service on this node. This will also stop postgres and thus terminate all remaining db connections if there are still some. With the patroni service stopped, you should see this node vanish from the cluster after a while when you run `gitlab-patronictl list` on any of the other nodes. 

We have alerts that fire when patroni is deemed to be down. Since this is an intentional change - either silence the alarm in advance and/or give a heads up to the EOC (by messaging `@sre-oncall` at `#infrastructure-lounge` Slack channel).

- Stop the patroni service on the unhealthy node

	```
	sudo systemctl stop patroni
	sudo systemctl disable patroni.service
	```

- Check that patroni service is stopped in the host

   ```
   sudo gitlab-patronictl list
   ``` 


### Step 2 - Shutdown the node

- Stop the VM
	
	```
	gcloud compute instances stop <vm_name> 
	```



### Step 3 - Delete the VM and disks

- List the VM Disks

	```
	INSTANCE_NAME="<VM_NAME>"
	IFS=","
	for disk in $(gcloud compute instances describe $INSTANCE_NAME --format="value(disks.source.basename().list())")
	do
	    echo "Run: gcloud compute disks delete $disk"
	done
	```
	
	_To-Do: ideally we should just list the disks where `disks.autoDelete=False`_

- Take note of the VM Disks to delete them latter

- Delete the VM
	
	```
	gcloud compute instances delete <VM_NAME>
	```

- Delete the Disks
	- Execute the commands of the list VM disks


- Confirm that Compute instances and disks were deleted in the GCP console:
	- https://console.cloud.google.com/compute/instances
	- https://console.cloud.google.com/compute/disks

## Replacing the replica


### Step 1 - Check if Terraform will re-create the removed node

- Go into the proper Terraform environment workspace, within `config-mgmt/environments/<environment>`

- Perform a Terraform plan and check the resources that will be created

	```
	tf plan
	```

- TF should create 4 resources for each removed Patroni Replica: 3 disks, 1 network interface and 1 VM/instance


### Step 2 - Recreate the removed node

- Create the new resources

	```
	tf apply 
	```



## Automation Thoughts



## Reference

[Patroni Management Internal Doc](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/patroni/patroni-management.md). 