# Blue Green Deployments

## Background

At the moment we are working on improving the deployments for our runner
managers, this work can be tracked with
[&456](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/456). Our
end goal is to have an automated way to do [blue green
deployments](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/blue-green-deployments.pdf).
At the moment the steps are a moving target but we need to have the
process documented so that we know what we need to automate.

## Supported shards

- `private`

## Glossary

- `chef-repo`: https://gitlab.com/gitlab-com/gl-infra/chef-repo where
  all chef configuration is located.
- `terraform`:
  https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure where all
  the terraform code is located.
- `deployment`: Referring if `blue` or `green` is active, it can also be
  both.

## Deployment Example

We will give an example of how to deploy from `v14.1.0-rc1` to `v14.1.0` on
the `private` shard. This isn't meant to be a checklist because it will
change very friendly so sticking to an example might be easier to follow
and document for now.

*Note: All `knife` commands should be executed in
`lb-bastion.ci.gitlab.com` with a tmux/screen session since they are
long running process.*

1. `blue` deployment is [active](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/84c9b3cdfd76e108243f57910d5ac59971038538/environments/ci/runner-managers.tf#L82-83)
  via `terraform`, and running [`v14.1.0-rc1`](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/blob/dfb57033011ced4fea6fc7210331be72a0e1c75c/roles/runners-manager-private-blue.json#L12-13) configured by `chef-repo`.
1. Open a merge request to `chef-repo` to update the version for the
`green` deployment. :point_right: https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/364
    1. Make sure the merge request has the `~deploy` and
    `~group::runner` labels.
    1. Get the [merge request](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests/364) merged.
1. Run `chef-client` on the `green` deployment to install `v14.1.0`: `knife ssh -afqdn 'roles:runners-manager-private-green' -- 'sudo -i chef-client-enable && sudo -i chef-client'`.
1. When `green` deployment is active and healthy trigger a graceful
  shutdown to the `blue` deployment to stop the `gitlab-runner` process
  and wait for all jobs to finish:
      1. `knife ssh -afqdn 'roles:runners-manager-private-blue' -- 'sudo -i chef-client-disable "Disable chef until the next deployment"'`.
      1. `knife ssh -afqdn 'roles:runners-manager-private-blue' -- 'sudo -i systemctl stop gitlab-runner'`. This will start draining the runner and deleting the machines so this command will take a while to run!
      1. `knife ssh -afqdn 'roles:runners-manager-private-blue' -- 'sudo -i systemctl disable gitlab-runner'`.

### Deficiencies

1. We still depend on the engineers laptop to run knife commands:
    1. Destroy deactivated deployment :point_right: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/13795
    1. Automate shutdown command inside of GitLab CI pipeline :point_right: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/13803
1. Remove double concurrency window during deployment :point_right: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/13844
