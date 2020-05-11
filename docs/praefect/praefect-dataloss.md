# Dataloss in Praefect

In the situation where data loss is suspected, there are some diagnostic tools and a recovery tool that can be used.

## Identifying Impact of a Primary Node Failure

When a primary Gitaly node fails, there is a chance of data loss. Data loss can occur if there were outstanding replication jobs the secondaries did not manage to process before the failure. The Praefect `dataloss` sub-command helps identify these cases by counting the number of dead replication jobs for each repository within a given time frame.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss -from <rfc3339-time> -to <rfc3339-time>
```

If the time frame is not specified, dead replication jobs from the last six hours are counted:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss

Failed replication jobs between [2020-01-02 00:00:00 +0000 UTC, 2020-01-02 06:00:00 +0000 UTC):
example/repository-1: 1 jobs
example/repository-2: 4 jobs
example/repository-3: 2 jobs
```

To specify a time frame in UTC, run:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss -from 2020-01-02T00:00:00+00:00 -to 2020-01-02T00:02:00+00:00
```

### Checking repository checksums

To check a project's checksums across all nodes, the Praefect replicas Rake task can be used:

```shell
sudo gitlab-rake "gitlab:praefect:replicas[project_id]"
```

## Backend Node Recovery

When a Praefect backend node fails and is no longer able to
replicate changes, the backend node will start to drift from the primary. If
that node eventually recovers, it will need to be reconciled with the current
primary. The primary node is considered the single source of truth for the
state of a shard. The Praefect `reconcile` sub-command allows for the manual
reconciliation between a backend node and the current primary.

Run the following command on the Praefect server after all placeholders
(`<virtual-storage>` and `<target-storage>`) have been replaced:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -virtual <virtual-storage> -target <target-storage>
```

- Replace the placeholder `<virtual-storage>` with the virtual storage containing the backend node storage to be checked.
- Replace the placeholder `<target-storage>` with the backend storage name.

The command will return a list of repositories that were found to be
inconsistent against the current primary. Each of these inconsistencies will
also be logged with an accompanying replication job ID.