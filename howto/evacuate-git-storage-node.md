# Moving all repositories from one storage node to another

1. For production, make a public announcement that we will be performing
   maintenance resulting in rolling repository-level unavailability to writes,
   of time duration ~minutes.  An internal company announcement has already been
   made for staging.

1. From now on, each step will contain rollback instructions. Follow them in
   reverse order.

1. Provision nodes with the role "gstg-base-stor-gitaly-zfs". In staging, this
   is done by incrementing node_count on the "file-zfs" terraform resource:
   https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/blob/master/environments/gstg/main.tf#L821.
   This resource hasn't been created yet for production, but creating an MR
   should be simple.
  
    1. If you get a zone-specific resource exhaustion error (i.e. one that is
       not to do with GCE instance/disk quotas, which are regional), consider
       opening a GCP ticket if the rollout can be delayed. Alternatively, we can
       implement "zone overweightness" as seen in production for the gitaly
       fleet today.  See
       https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7187.
       
       For this reason, it's a good idea to provision the fleet in advance of
       the actual migration.

    1. No rollback is required for this step. It's harmless to have the nodes
       provisioned! You can always delete them with terraform if you like, after
       toggling deletion_protection. Make sure no repositories are present on
       the nodes before you do this.

1. Follow
   https://gitlab.com/gitlab-com/runbooks/blob/master/howto/storage-servers.md
   to configure and test the Gitaly node, but do not perform the last step which
   configures the GitLab application to use the node for new repository storage.

    1. Rollback: move any test repositories back to other nodes, then revert the
       chef config change so that GitLab is not aware of the ZFS-backed node(s).

1. Push a dummy repository. Write down the storage node that it's on, then move
   it to a new ZFS node.

    1. To find the storage node a repository is stored on, run the following in
       a rails console:
       `Project.find_by_full_path('namespace/name').repository_storage`.

    1. Before moving repositories in a console: unless
       https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/14908 has been
       merged and deployed, monkey patch `EE::Project` as shown in
       [scripts/move_all_repos_between_nodes.rb](scripts/move_all_repos_between_nodes.rb).

    1. To move a repository: `project.change_repository_storage('new-storage',
       sync: true)`.

    1. Rollback: move the dummy repo back.

1. Using the GitLab admin UI, disable one node from receiving new repositories.
   Enable the new ZFS node.

    1. Rollback: reverse the enabling and disabling. Move any repositories that
       have landed on the ZFS node to the ext4 node.

1. Move all repositories in batches from the old node to the new ZFS node.

    1. See scripts/move_all_repos_between_nodes.rb for up-to-date usage
       instructions.

    1. Assuming you have redirected output to a log file as described in the
       comment at the top of the script: `grep 'excluding for manual triage'
       log_file`. This will list the projects that could not move. See the below
       section for more details on what to do here.

    1. Rollback: same as previous step.

1. Check that there are no projects on logical shards corresponding to the
   physical git file store:

   1. In a rails console, for each logical shard:
      `Project.where(repository_storage: 'nfs-fileXX').count`
   1. In production, at the time of writing, a logical shard corresponds 1:1
      with a physical server.

1. Decommission the old file store node.

   1. Ensure that logical shards kept on this server are not accepting new repos
      (using the admin panel).
   1. Having completed the previous step, you should be satisfied there are no
      repositories stored on this server.
   1. Using the GCP console, stop the machine.
   1. Take a snapshot of its data disk, for safe keeping.
   1. Delete the machine and disk.
   1. This will create a terraform plan diff, but so will pretty much any other
      decommissioning strategy unless the machine in question is the final
      index, making it safe to decrement the count.
   1. When all machines in a fleet have been decommissioned, you can then remove
      the terraform module declaring the machines, and apply.

## Projects that refuse to move

At the time of writing, 2 projects (on staging) have been observed not to move,
and the migration script logs "excluding for manual triage". This reason is that
the repository disk path of the project doesn't actually exist. You can still
load the project page, but an error will be shown where the file browser would
normally be.

No decision has currently been made as to what to do about these projects, but
it might be wise to simply delete them from staging, and wait to see if the
problem even exists in production.
