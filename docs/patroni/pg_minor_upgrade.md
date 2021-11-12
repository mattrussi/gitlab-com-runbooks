# Postgresql minor upgrade 

This runbook describes all the steps to execute a Postgresql minor upgrade. 

Considering the database, one of the most critical components from our infrastructure, we want to execute the upgrade node by node by executing tests, monitoring the performance and behavior after the upgrade in each node.

Those changes are automated on the following playbook:

```
..\pg_minor_upgrade.yml
```

## The main steps

The main steps on the read-only replicas, are:

* Disable chef-client.

 - Execute the command: `chef-client-disable`

Add the `no-failover` and `no-loadbalance` tags in Patroni ( in the config file patroni.yml).

### Pre checks:
Wait until the traffic is drained. 
Execute a checkpoint. Command: `gitlab-psql -c "checkpoint;"`

Shutdown PostgreSQL

### Main actions:
Update the binaries:

```
# get a list of installed packages
sudo dpkg -l | grep postgres
# retrieve new lists of packages
sudo apt-get update -y
# update postgresql packages:
sudo apt-get install -y postgresql-client-12 postgresql-12 postgresql-server-dev-12 --only-upgrade
# update extensions packages:
sudo apt-get install -y postgresql-12-repack --only-upgrade
​# optional:
sudo apt-get install -y postgresql-common postgresql-client-common --only-upgrade
```
Start PostgreSQL

Update extensions:
```
-- Get a list of installed and available versions of extensions in the current database: 
select ae.name, installed_version, default_version,
case when installed_version <> default_version then 'OLD' end as is_old
from pg_extension e
join pg_available_extensions ae on extname = ae.name
order by ae.name;

-- Update 'OLD' extensions (example):
ALTER EXTENSION pg_stat_statements UPDATE;
```

### Post checks
Check connectivity with the command: `gitlab-psql -c "select pg_is_in_recovery();"`
Verify the version with the command: `gitlab-psql -c "select pg_version();"`
Check logs
Restore the traffic by starting chef, which will remove the tags on the node.


After restoring the traffic, monitor the performance for 30 minutes from the node and the logs.

After executing the above process, to upgrade the primary node we could execute a switchover first.