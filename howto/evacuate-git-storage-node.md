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

    1. **This step is a work-in-progress**. See
       scripts/move_all_repos_between_nodes.rb, but note that this has not been run
       (outside of a dry run).

    1. Rollback: same as previous step.
