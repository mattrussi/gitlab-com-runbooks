# Praefect has read-only repositories

## Symptoms

* Alert: `Some repositories are in read-only mode.`

* Mutator RPCs through Praefect fail with `FailedPrecondition` code and message `repository is in read-only mode`.

* [Read-only metric is not at 0](https://dashboards.gitlab.com/d/8EAXC-AWz/praefect?viewPanel=40&orgId=1).

* Logs contain error message `repository is in read-only mode` originating from Praefect.

## Possible Causes

* Praefect might have failed over to an outdated secondary node.

## Actions

1. Praefect should be able to self-heal after a failover, eventually reconciling
   state between nodes and taking repositories out of read-only mode. This has
   been observed to take about 10 minutes in the past
   (https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3709). The
   "repositories in read-only" alert has been adjusted to only fire after
   repositories have been in a read-only state for over 15 minutes, and so the
   presence of this alert may indicate that the self-healing mechanism has
   failed. Even so, check the read-only metric (see "symptoms" above), and
   proceed with the following manual recovery steps if it is not decreasing
   after some time has passed.
1. Check which virtual storage contains read-only repositories. This should be visible in either the alert, the dashboard or the logs.
1. Identify the up to date and outdated replicas with `praefect dataloss`
   1. On a Praefect node, run the following command subsituting the `<virtual-storage>` with the correct one.

      ```shell
      sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss -virtual-storage <virtual-storage>
      ```

   1. The current primary is listed along with repositories with outdated replicas. Any nodes not listed in the output are up to date and can be reconciled from as long as they are available.
   1. Reconcile to each of the outdated replicas (`-target`) using an available, up to date node as the source (`-reference`). While read-only mode is resolved as soon as the primary contains the latest changes, you should also reconcile to outdated secondaries to ensure the data is properly replicated.

      ```shell
      sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -f -virtual <virtual-storage> -reference <up-to-date-storage> -target <outdated-storage>
      ```

    1. Verify using the `praefect dataloss` that there are no read-only repositories. It might take a while to see the changes as `praefect reconcile` only schedules the replication jobs which are then processed asynchronously.

## Accept Data Loss

**Caution:** Only do this if losing data is acceptable. This will overwrite any other version of the repository on the virtual storage.

If the nodes that contain the latest changes are gone for good, recovering the data is not possible. In order to return the repository in to writable state, data loss can be manually accepted. To do so:

1. Identify which node's version of the repository you'd like to use going forward. `praefect dataloss` tells you how many changes each node is behind by maximum. Listed nodes may also contain later changes but it is not possible to determine that without manual inspection.
   ```shell
   sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss -virtual-storage <virtual-storage>
    ```
1. From the output, select the version of the repository to use as the authoritative version. Usually this would be the the node that is least behind by maximum.
1. Use `praefect accept-dataloss` to set the new authoritative version. Replace `<authoritative-storage>` with the storage that contains the version to use going forward. Replace `<relative-path>` with the relative path of the repository to accept data loss for.
   ```
   sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss\
     -virtual-storage <virtual-storage> \
     -authoritative-storage <authoritative-storage> \
     -repository <relative-path>
   ```
1. `praefect accept-dataloss` schedules replication jobs to other nodes to bring them consistent with the new version.
   The repository is writable again as soon as the primary has replicated the selected version or immediately if it was selected.
