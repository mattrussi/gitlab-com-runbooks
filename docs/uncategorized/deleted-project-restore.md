# Deleted Project Restoration

# You should not perform this action

As a general policy, we do not perform these restores. You should refuse to perform this restore unless the request is escalated to an Infrastructure manager.

Plan on two or three days of effort over a five day time period for a successful restore. And even then, there is no guarantee of full recovery.

## Introduction

As long as we have the database and Gitaly backups, we can restore deleted GitLab
projects.

It is strongly suggested to read through this entire document before proceeding.

There is an alternate runbook for a different method of [restoring namespaces](namespace-restore.md), but the one in this document should be preferred.

## Background

There are two sources of data that we will be restoring: the project metadata
(issues, merge requests, members, etc.), which is stored in the main database
(Postgres), and the repositories (main and wiki) which are stored on a Gitaly
shard.

Container images and CI artifacts are not restored by this process.

## Part 1: Restore the project metadata

If a project is deleted in GitLab, it is entirely removed from the database.
That is, we also lack the necessary metadata to recover data from file servers.
Recovering meta- and project data is a multi-step process:

1. Restore a full database backup and perform point-in-time recovery (PITR)
2. Extract metadata necessary to recover from git/wiki data from file servers
3. Export the project from the database backup and import into GitLab

### Special procedure if the deletion was less than 8h ago

We run a delayed archive replica of our production database, with
`recovery_min_apply_delay = '8h'`. It is therefore at least
8h behind the production database at all times. If the request for restoration
comes quickly enough, we can skip the creation of a PITR instance and use this
delayed-replica instead.

Note that this procedure has not been used, and is speculative. Inform the
engineer on-call before continuing. This will likely set off alerts due to
lagging replication, which will need to be silenced for the duration of this
procedure.

1. `ssh` to the delayed replica.
1. In a `gitlab-psql` shell: `SELECT pg_wal_replay_pause();`
1. `systemctl stop chef-client.service`
1. In a `gitlab-psql` shell: `select now()-pg_last_xact_replay_timestamp() as replication_lag;` and replication lag should start increasing.

Later, when you have extracted the project export:

1. In a `gitlab-psql` shell: `SELECT pg_wal_replay_resume();`
1. `systemctl start chef-client.service`

Continue at "Export project from database backup and import into GitLab".

### Restore full database backup and perform PITR

If the request arrived promptly and you were able to follow the special
procedure above, skip this section.

In order to restore from a database backup, we leverage the backup restore pipeline in "gitlab-restore" project. It can be configured to start a new GCE instance and restore a backup to an exact point in time for later recovery ([example MR](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/merge_requests/8/diffs)). Currently, Postgres backups are created by WAL-G. Use `WAL_E_OR_WAL_G` CI variable to switch to WAL-E if needed (see below).

1. Push a commit similar to the example MR above. Note that you don't need to
   create an MR although you can if you like.
1. You can start the process in [CI/CD Pipelines](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/pipelines/new) of the "gitlab-restore" project.
1. Select your branch, and configure the variables as detailed in the steps below.
1. To perform PITR for the production database, use CI/CD variable `ENVIRONMENT` set to `gprd`. The default value is `gstg` meaning that the staging database will be restored.
1. To ensure that your instance won't get destroyed in the end, set CI/CD variable `NO_CLEANUP` to `1`.
1. In CI/CD Pipelines, when starting a new pipeline, you can choose any Git branch. But if you use something except `master`, there are high chances that production DB copy won't fit the disk. So, use `GCE_DATADISK_SIZE` CI/CD variable to provision an instance with a large enough disk. As of January 2020, we need to use at least `6000` (6000 GiB). Check the `GCE_DATADISK_SIZE` value that is currently used in the backup verification schedules (see [CI/CD Schedules](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/pipeline_schedules)).
1. By default, an instance of `n1-standard-16` type will be used. Such instances have "good enough" IO throughput and IOPS quotas [Google throttles disk IO based on the disk size and the number of vCPUs](https://cloud.google.com/compute/docs/disks/performance#ssd-pd-performance)). In the case of urgency, to get the best performance possible on GCP, consider using `n1-highcpu-32`, specifying CI/CD variable `GCE_INSTANCE_TYPE` in the CI/CD pipeline launch interface. It is highly recommended to check the current resource consumption (total vCPUs, RAM, disk space, IP addresses, and the number of instances and disks in general) in the [GCP quotas interfaces of the "gitlab-restore" project](https://console.cloud.google.com/iam-admin/quotas?project=gitlab-restore).
1. It is recommended (although not required) to specify the instance name using CI/CD variable `INSTANCE_NAME`. Custom names help distinguish GCE instances from auto-provisioned and from provisioned by someone else. An excellent example of custom name: `nik-gprd-infrastructure-issue-1234` (means: requested by `nik`, for environment `gprd`, for the the `infrastructure` issue `1234`). If the custom name is not set, your instance gets a name like `restore-postgres-gprd-XXXXX`, where `XXXXX` is the CI/CD pipeline ID.
1. As mentioned above, by default, WAL-G will be used to restore from a backup. It is controlled by CI variable `WAL_E_OR_WAL_G` (default value: `wal-g`). If WAL-E is needed, set CI variable `WAL_E_OR_WAL_G` to `wal-e`, but expect that restoring will take much more time. For the "restore basebackup" phase, on `n1-standard-16`, the expected speed of filling the PGDATA directory is 0.5 TiB per hour for WAL-E and 2 TiB per hour for WAL-G.
1. To control the process, SSH to the instance. The main items to check:
    - `df -hT /var/opt/gitlab` to ensure that the disk is not full (if it hits 100%, it won't be noticeable in the CI/CD interfaces, unfortunately),
    - `sudo journalctl -f` to see basebackup fetching and, later, WAL fetching/replaying happening.
1. Finally, especially if you have made multiple attempts to provision an instance via CI/CD Pipelines interface, check [VM Instances](https://console.cloud.google.com/compute/instances?project=gitlab-restore&instancessize=50) in GCP console to ensure that there are no stalled instances related to your work. If there are some, delete them manually. If you suspect that your attempts failing because of some WAL-G issues, try WAL-E (see above).

The instance will progress through a series of operations:

1. The basebackup will be downloaded
1. The Postgres server process will be started, and will begin progressing past
   the basebackup by recovering from WAL segments downloaded from GCS.
1. Initially, Postgres will be in crash recovery mode and will not accept
   connections.
1. At some point, Postgres will accept connections, and you can check its
   recovery point by running `select pg_last_xact_replay_timestamp();` in a
   `gitlab-psql` shell.
1. Check back every 30 minutes or so until the recovery point you wanted has been
   reached. You don't need to do anything to stop further recovery, your branch
   has configured it to pause at this point.

After the process completes, an instance with a full GitLab installation and a
production copy of the database is available for the next steps.

Note that the startup script will never actually exit due to the branch
configuration that causes Postgres to pause recovery when some point is reached.
It [loops
forever](https://ops.gitlab.net/gitlab-com/gl-infra/gitlab-restore/postgres-gprd/blob/8d011b3f8a29582d358374adde6f701fe382c03d/bootstrap.sh#L161-164)
waiting for a recovery point equal to script start time.

### Export project from database backup and import into GitLab

Here, we use the restored database instance with a GitLab install to export the project through the standard import/export mechanism. We want to avoid starting a full GitLab instance (to perform the export throughout the UI) because this sits on a full-sized production database. Instead, we use a rails console to trigger the export.

1. Start Redis: `gitlab-ctl start redis` (Redis is not going to be used really, but it's a required dependency)
2. Start Rails: `gitlab-rails console`

Modify the literals in the following console example and run it. This retrieves
a project by its ID, which we obtain by searching for it by namespace ID and its
name. We also retrieve an admin user. Use yours for auditability. The
ProjectTreeSaver needs to run "as a user", so we use an admin user to ensure
that we have permissions.

```ruby
irb(main):001:0> user = User.find_by_username('an-admin')
=> #<User id:1234 @an-admin>
irb(main):002:0> project = Project.find_by_full_path('namespace/project-name')
=> #<Project id:5678 namespace/project-name>

irb(main):003:0> project.repository_storage
... note down this output...

irb(main):004:0> project.disk_path
... note down this output ...

irb(main):005:0> shared = Gitlab::ImportExport::Shared.new(project)
irb(main):006:0> version_saver = Gitlab::ImportExport::VersionSaver.new(shared: shared)
irb(main):007:0> tree_saver = Gitlab::ImportExport::Project::TreeSaver.new(project: project, current_user: user, shared: shared)
irb(main):009:0> version_saver.save
irb(main):010:0> tree_saver.save

irb(main):011:0> include Gitlab::ImportExport::CommandLineUtil
irb(main):012:0> archive_file = File.join(shared.archive_path, Gitlab::ImportExport.export_filename(exportable: project))
irb(main):013:0> tar_czf(archive: archive_file, dir: shared.export_path)
... some output that includes the path to a project tree directory, which will be something like /var/opt/gitlab/gitlab-rails/shared/tmp/gitlab_exports/@hashed/. Note this down.
```

We now have the Gitaly shard and path on persistent disk the project was stored
on, and if the final command succeeded, we have a project metadata export JSON.

It's possible that the save command failed with a "storage not found" error. If
this is the case, edit `/etc/gitlab/gitlab.rb` and add a dummy entry to
`git_data_dirs` for the shard, then run `gitlab-ctl reconfigure`, and restart
the console session. We are only interested in the project metadata for now, but
the `Project#repository_storage` must exist in config.

An example of the `git_data_dirs` config entry in `gitlab.rb`:

```
git_data_dirs({
  "default" => {
    "path" => "/mnt/nfs-01/git-data"
   },
  "nfs-file40" => {
    "path" => "/mnt/nfs-01/git-data"
   }
})
```

You can safely duplicate the path from the `default` git_data_dir, it doesn't
matter that it won't contain the repository.

Make the project.json accessible to your `gcloud ssh` user:

```
mv /path/to/project/tree /tmp/
chmod -R 644 /tmp/project
```

Download the file, replacing the project and instance name in this example as
appropriate: `gcloud --project gitlab-restore compute scp -r
restore-postgres-gprd-88895:/tmp/project ./`

Download [a
stub](https://gitlab.com/gitlab-com/gl-infra/infrastructure/uploads/832946b5bd7474ac51a976e42bee4afb/blank_export.tar.gz)
exported project.

On your local machine, replace the project.json inside the stub archive with the
real one:

```
mkdir repack
tar -xf test_project_export.tar.gz -C repack
cd repack
cp ../project.json ./
tar -czf ../repacked.tar.gz ./
```

Log into gitlab.com using your admin account, and navigate to the namespace in
which we are restoring the project. Create a new project, using the "from GitLab
export" option. Name it after the deleted project, and upload repacked.tar.gz.

A project can also be imported on the [command
line](https://gitlab.com/gitlab-com/gl-infra/infrastructure/blob/master/.gitlab/issue_templates/import.md).

This will create a new project with equal metadata to the deleted one. It will
have a stub repo and wiki. The persistent object itself is new: it has a new
project_id, and the repos are not necessarily stored on the same Gitaly shard,
and will have new disk_paths.

Browse the restored project's member list. If your admin account is listed as a
maintainer, leave the project.

Start a production console, and locate the new project object using the same
method as above. Note down its `repository_storage` and `disk_path`. These point
us to the stub repo (and wiki repo) that we'll now replace with a backup.

## Part 2: Restore Git repositories

The first step is to check if the repositories still exist at the old location.
They likely do not, but it's possible that unlike project metadata they have not
(yet) been removed.

Using the repository_storage and disk_path obtained from the DB **backup** (i.e.
for the old, deleted project metadata), ssh into the relevant Gitaly shard and
navigate to `/var/opt/gitlab/git-data/repositories`. Check if `<disk_path>.git`
and `<disk_path>.wiki.git` exist. If so, create a snapshot of this disk in the
GCE console.

If these directories do not exist, browse GCE snapshots for the last known good
snapshot of the Gitaly persistent disk on which the repository used to be
stored.

Either way, you now have a snapshot with which to follow the next steps.

### Restoring from Disk Snapshot

Run all commands on the server in a root shell.

1. Create a new disk from the snapshot. Give it a relevant name and description,
   and ensure it's placed in the same zone as the Gitaly shard referenced by the
   **new** project metadata (i.e. that obtained from the production console).
1. In the GCE console, edit the Gitaly shard on which the new, stub repositories
   are stored. Attach the disk you just created with a custom name "pitr".
1. GCP snapshots are not guaranteed to be consistent. Check the filesystem:
   `fsck.ext4 /dev/disk/by-id/google-pitr`. If this fails, do not necessarily
   stop if you are later able to mount it: the user is already missing their
   repository, and if we are lucky the part of the filesystem containing it is
   not corrupted. Later, we ask the customer to check the repository, including
   running `git fsck`. Unfortunately it's possible that the repository would
   already have failed this check, and we can't know.
1. Mount the disk: `mkdir /mnt/pitr; mount -o ro /dev/disk/by-id/google-pitr
   /mnt/pitr`
1. Navigate to the parent of
   `/var/opt/gitlab/git-data/repositories/<disk_path>.git`.
1. `mv <new_hash>.git{,moved-by-your-name}`, and similar for the wiki
   repository. Reload the project page and you should see an error. This
   double-checks that you have moved the correct repositories (the stubs). You
   can `rm -rf` these directories now. `<new_hash>` refers to the final
   component of the new `disk_path`.
1. `cp -a /mnt/pitr/git-data/repositories/<old_disk_path>.git ./<new_hash>.git`,
   and similarly for the wiki repo. If you've followed the steps up to now your
   CWD is something like `/var/opt/gitlab/git-data/repositories/@hashed/ab/cd`.
1. Reload the project page. You should see the restored repository, and wiki.
1. `umount /mnt/pitr`
1. In the GCE console, edit the Gitaly instance, removing the pitr disk.

## Part 3: Check in with the customer

Once the customer confirms everything is restored as expected, you can delete
any disks, and Postgres PITR instances created by this process.

It might be worth asking the customer to check their repository with `git fsck`.
If the filesystem-level fsck we ran on the Gitaly shard succeeded, then the
result of `git fsck` doesn't matter that much: the repository might already have
been corrupted, and that's not necessarily our fault. However, if both `fsck`s
failed, we can't know whether the corruption predated the snapshot or not.

# Troubleshooting

## Rails console errors out with a stacktrace

You may need to copy the production `db_key_base` key into the restore node. You can find the key in `/etc/gitlab/gitlab-secrets.json`.

## Gitlab reconfigure fails

You may need to edit the `/etc/gitlab/gitlab.rb` file and disable object_store like this: `gitlab_rails['object_store']['enabled'] = false`

## Copying the Git repository results in a bad fsck or non-working repository

You may be recovering a repository with objects in a shared pool. Try to
re-copy using [these instructions](../gitaly/git-copy-by-hand.md).
