# Gitaly Balancer Project

This [project](https://gitlab.com/gitlab-com/gl-infra/balancer) is meant to move gitaly repositories in bulk from one Gitaly node to another, in case of storage/disk saturation. The project is hosted on ops.gitlab.net and runs [scheduled job](https://ops.gitlab.net/gitlab-com/gl-infra/balancer/-/pipeline_schedules) to detect overloaded gitaly nodes and pick one (configurable) of them to move repositories away from it to a gitaly node with more available disk space. It currently moves around 1000 GB of project repositories on each run.

## Scheduled job

Currently [scheduled job](https://ops.gitlab.net/gitlab-com/gl-infra/balancer/-/pipeline_schedules) runs in production once a day at 01:00 UTC with following configurations (set via job variables):

- SHARD_LIMIT: 1 (Selects single shard to move repositories from)
- MOVE_AMOUNT: 1000 (Moves 1000 GB of projects or less)
- MOVE_LIMIT: -1 (There is no limit on the amount of repositories to move)

More information on CI variables is available here: <https://ops.gitlab.net/gitlab-com/gl-infra/balancer#using-balancer-through-ci>

## Project docs

For information related to project setup and running the job manually, please refer to project readme: <https://ops.gitlab.net/gitlab-com/gl-infra/balancer/-/blob/main/README.md>
Here is a recorded video of project walkthrough: <https://youtu.be/kEuYNVDpTUk>
