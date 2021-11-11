# Postgresql minor upgrade 

This runbook describes all the steps to execute a Postgresql minor upgrade. 

Considering the database of the most critical components from our infrastructure, we want to execute the upgrade node by node, having tests and monitoring the performance and behavior after the upgrade in each node.

Those changes are automated on the following playbook:

```
..\pg_minor_upgrade.yml
```

## The main steps
The main steps on the read onlies replicas, one by one:

* Disable chef-client.

 - Execute the command: `chef-client-disable`

Add the tags of no failover and no-load balance in Patroni.

### Pre checks:
Wait until the traffic is drained.
Execute a checkpoint
Shutdown PostgreSQL

### Main actions:
Update the binaries and extensions by the commands:
Start PostgreSQL

### Post checks
Check connectivity 
Verify the version
Check logs
Restore the traffic by starting chef that will remove the tags on the node.


After restoring the traffic monitor for 30 min the performance from the node and the logs.

After executing the process above, to upgrade the primary we could execute a switchover
