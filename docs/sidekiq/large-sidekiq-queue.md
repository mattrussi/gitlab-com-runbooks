# [`SidekiqQueueTooLarge`](../../rules/sidekiq-queues.yml)

**Table of Contents**

[TOC]

* [Previous Incidents](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=a%3ASidekiqQueueTooLarge&first_page_size=20)
* [Queue Detail Dashboard](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq3a-queue-detail?orgId=1)
* [Shard Detail Dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-stage=main&var-shard=catchall&from=1702857600000&to=1702943999000)

## Symptoms

![large sidekiq Queue](./img/sidekiq-large-queue.png)

[source](https://thanos.gitlab.net/graph?g0.expr=max(sidekiq_queue_size%7Benv%3D%22gprd%22%2C%20name%3D%22default%22%7D)&g0.tab=0&g0.stacked=0&g0.range_input=6h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D&g0.end_input=2023-12-18%2015%3A30%3A00&g0.moment_input=2023-12-18%2015%3A30%3A00)

## Debugging

1. Check inflight workers for a specific shard: <https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&viewPanel=11>
    * A specific worker might be running a large amount of jobs.
1. Check started jobs for a specific queue: <https://log.gprd.gitlab.net/app/r/s/v28cQ>
    * A specific worker might be enqueing a lot of jobs.
1. Latency of job duration: <https://log.gprd.gitlab.net/app/r/s/oZnYz>
    * We might be finishing jobs slower, so we get queue build up.
1. Throughput: <https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-stage=main&var-shard=catchall&viewPanel=17>
    * If there is a sharp drop of a specific worker it might have slowed down.
    * If there is a sharp increase of a speicific worker it's saturating the queue.

## Resolution

### Increase Capacity

You can increase the [`maxReplicas`](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/28d3a55911185087719b183cc4bbca589154bf37/releases/gitlab/values/gprd.yaml.gotmpl#L570) for the specific shard.

Things to keep in mind:

1. If we run more concurrent jobs it might add more pressure to downstream services (Database, Gitaly, Redis)
1. Check if this was a sudden spike or if it's sustained load.

### New Worker

It could be that this is a new worker that started running hopefully behind a feature flag that we can turn off.

### Drop worker jobs

[Drop all jobs](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/sidekiq/disabling-a-worker.md#dropping-jobs-using-feature-flags-via-chatops),
be sure that droping the jobs is safe and won't leave the application in a wierd state.

### Mail queue

If the queue is all in `mailers` and is in the many tens to hundreds of thousands it is
possible we have a spam/junk issue problem.  If so, refer to the abuse team for assistance,
and also <https://gitlab.com/gitlab-com/runbooks/snippets/1923045> for some spam-fighting
techniques we have used in the past to clean up.  This is in a private snippet so as not
to tip our hand to the miscreants.  Often shows up in our gitlab public projects but could
plausibly be in any other project as well.

### Get queues using sq.rb script

[sq](https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/sidekiq/sq.rb) is a command-line tool that you can run to
assist you in viewing the state of Sidekiq and killing certain workers. To use it,
first download a copy:

```bash
curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/sidekiq/sq.rb
```

To display a breakdown of all the workers, run:

```bash
sudo gitlab-rails runner /tmp/sq.rb
```

### Remove jobs with certain metadata from a queue (e.g. all jobs from a certain user)

We currently track metadata in sidekiq jobs, this allows us to remove
sidekiq jobs based on that metadata.

Interesting attributes to remove jobs from a queue are `root_namespace`,
`project` and `user`. The [admin Sidekiq queues
API](https://docs.gitlab.com/ee/api/admin_sidekiq_queues.html) can be
used to remove jobs from queues based on these medata values.

For instance:

```shell
curl --request DELETE --header "Private-Token: $GITLAB_API_TOKEN_ADMIN" https://gitlab.com/api/v4/admin/sidekiq/queues/post_receive?user=reprazent&project=gitlab-org/gitlab
```

Will delete all jobs from `post_receive` triggered by a user with
username `reprazent` for the project `gitlab-org/gitlab`.

Check the output of each call:

1. It will report how many jobs were deleted.  0 may mean your conditions (queue, user, project etc) do not match anything.
1. This API endpoint is bound by the HTTP request time limit, so it will delete as many jobs as it can before terminating. If the `completed` key in the response is `false`, then the whole queue was not processed, so we can try again with the same command to remove further jobs.
