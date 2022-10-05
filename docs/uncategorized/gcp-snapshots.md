# Google Cloud Snapshots

We utilize GCP [Scheduled Snapshots](https://cloud.google.com/compute/docs/disks/scheduled-snapshots) to
automate the creation and the cleaning-up of disk snapshots. The schedule policy is created in Terraform
([example in staging](https://gitlab.com/gitlab-com/gl-infra/config-mgmt/-/blob/d7287a47adfdca6cce76ca455e0684863f248e57/environments/gstg/main.tf#L262)),
currently is configured to take a snapshot every 4 hours and keep all snapshots for 14 days. Individual modules (e.g. `postgres-dr-delayed`)
has to be configured to attach its disk to the snapshot policy, usually by specifying the `data_disk_snapshot_policy` variable, but this
could be different depending on the underlying module provision the resource.

Previously, we used to take snapshots of each disk with the label `do_snapshots=true` by means of scheduled CI job
([example in production](https://gitlab.com/gitlab-restore/gitlab-production-snapshots)).

## Alerting

We have an alert to check if snapshots are being created every hour as expected. In the event of this alert being triggered,
we need to check the existence of the snapshot policy ([example](https://gitlab.com/gitlab-com/gl-infra/config-mgmt/-/blob/d7287a47adfdca6cce76ca455e0684863f248e57/environments/gstg/main.tf#L262))
and that there are disks attached to it. This can be viewed quickly from the GCP dashboard (Compute Engine > Storage > Snapshots > Snapshot Schedules).

If the resources are there as expected, we can check Stackdriver logs for errors. One reason for errors could be hitting the quota for number of snapshots, in which case
consider either removing old ones, increasing the quota for snapshots or decreasing the interval at which we take snapshots.

## Manual Restore Procedure

1. Manually create a server in GCP. Sizing doesn't matter too much here.
1. Create disks from the snapshots you wish to restore/test. The snapshots have weird names. They should be standardized, but you can find the snapshots in the GCP panel and search by source server name.
1. Attach these disks to the server created in step one. If you are trying to test multiple disks, you can attach them all to the same server.
1. Run an `fsck` on the disk(s) that you wish to test. This will potentially take over an hour for large disks like file servers, but are much faster for smaller servers. I tested with `time fsck -fy /dev/sdX`.
1. If the `fsck` finishes successfully, mount the disk(s) and run a find to exercise the disk. In my test I mounted all the disks to `/mnt/<disk name>` and then ran a `find` to go through /mnt/ and thus all the disks. This could be improved.
1. This is all that was tested in our initial tests, but more could be added. You may now delete the test server and disks.
