# (Title: SidekiqQueueTooLarge)

**Table of Contents**

[TOC]

## Overview

- What does this alert mean?
This alert indicates that the Sidekiq queue has exceeded a predefined size threshold. This signifies a backlog of jobs waiting to be processed.
- What factors can contribute?
  - **Sudden Traffic Spikes**: Unexpected surges in workload can overwhelm Sidekiq's processing capacity, causing a queue buildup.
  - **Slow Workers**: Inefficient jobs or external dependencies causing slow processing can lead to task pile-up.
  - **Configuration Issues**: Limited Sidekiq worker processes might not be able to keep up with incoming jobs.
  - **Database Interactions**: Inefficient database queries or slow database performance can significantly impact task processing speed, leading to queue growth.
- What parts of the service are effected?
  - **Background Processing**: All background jobs managed by Sidekiq will experience delays.
  - **Time-sensitive** Jobs might be significantly impacted.
  - **Overall Application Performance**: Delayed background jobs can indirectly affect the responsiveness of your application.

![large sidekiq Queue](../img/sidekiq-large-queue.png)

## Services

- [Service Overview](../README.md)
- Team that owns the service: [Core Platform:Gitaly Team](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/gitaly/)

- **Label:** gitlab-com/gl-infra/production~"Service::Sidekiq"

## Verification

- [Queue Detail Dashboard](https://dashboards.gitlab.net/d/sidekiq-queue-detail/sidekiq3a-queue-detail?orgId=1)
- [PromQL Link](https://dashboards.gitlab.net/goto/HqewjWUSg?orgId=1)
- [Shard Detail Dashboard](https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-stage=main&var-shard=catchall&from=1702857600000&to=1702943999000)

## Troubleshooting

Analyze recent application changes, traffic patterns, and identify slow-running jobs.

- **Check inflight workers for a specific shard**: <https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&viewPanel=11>
  - A specific worker might be running a large amount of jobs.
- **Check started jobs for a specific queue**: <https://log.gprd.gitlab.net/app/r/s/v28cQ>
  - A specific worker might be enqueing a lot of jobs.
- **Latency of job duration**: <https://log.gprd.gitlab.net/app/r/s/oZnYz>
  - We might be finishing jobs slower, so we get queue build up.
- **Throughput**: <https://dashboards.gitlab.net/d/sidekiq-shard-detail/sidekiq3a-shard-detail?orgId=1&var-PROMETHEUS_DS=PA258B30F88C30650&var-environment=gprd&var-stage=main&var-shard=catchall&viewPanel=17>
  - If there is a sharp drop of a specific worker it might have slowed down.
  - If there is a sharp increase of a speicific worker it's saturating the queue.

## Resolution

### Scale Workers

Increase the number of concurrent Sidekiq workers if processing speed is the bottleneck.

- You can increase the [maxReplicas](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/28d3a55911185087719b183cc4bbca589154bf37/releases/gitlab/values/gprd.yaml.gotmpl#L570) for the specific shard. Things to keep in mind:
  - If we run more concurrent jobs it might add more pressure to downstream services (Database, Gitaly, Redis)
  - Check if this was a sudden spike or if it's sustained load.

### Check for new workers

It could be that this is a new worker that started running hopefully behind a feature flag that we can turn off.

### Mail queue

If the queue is all in mailers and is in the many tens to hundreds of thousands it is possible we have a spam/junk issue problem.  If so, refer to the abuse team for assistance, and also <https://gitlab.com/gitlab-com/runbooks/snippets/1923045> for some spam-fighting techniques we have used in the past to clean up.  This is in a private snippet so as not to tip our hand to the miscreants.  Often shows up in our gitlab public projects but could plausibly be in any other project as well.

### Get queues using sq.rb script

[sq](https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/sidekiq/sq.rb) is a command-line tool that you can run to assist you in viewing the state of Sidekiq and killing certain workers. To use it, first download a copy:

```
curl -o /tmp/sq.rb https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/sidekiq/sq.rb
```

To display a breakdown of all the workers, run:

```
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

## Metrics

[Sidekiq Queues Metrics](../../../rules/sidekiq-queues.yml)

This alert is based on the maximum value of the `sidekiq_queue_size` across different environments and queue names. It helps identify the queue with the most jobs waiting. It will complare the maximum queue size to a threshold of 50,000. If the maximum queue size exceeds 50,000 the alert triggers. This was based on historical data which under normal conditions the graph should show a consistent pattern

## Alert Behavior

- Information on silencing the alert (if applicable). When and how can silencing be used? Are there automated silencing rules?
  - If the current threshold is too sensitive for typical traffic, [adjust it to a more suitable level](https://alerts.gitlab.net/#/silences/new?filter=%7Balert_type%3D%22cause%22%2C%20environment%3D%22gprd%22%2C%20name%3D%22elasticsearch%22%2C%20pager%3D%22pagerduty%22%2C%20severity%3D%22s1%22%2C%20alertname%3D%7E%22SidekiqQueueTooLarge%22%7D).
- Expected frequency of the alert. Is it a high-volume alert or expected to be rare?
  - This is a rare alert and mainly happens when sidekiq is overloaded

## Severities

- The severity of this alert is generally going to be a ~severity::3 or ~severity::4
- There might be customer user impact depending on which queue is affected

## Recent changes

- [Recent Gitaly Production Change/Incident Issues](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=Service%3A%3AGitaly&first_page_size=20)
- [Chef Gitaly Changes](https://gitlab.com/gitlab-com/gl-infra/chef-repo/-/merge_requests?scope=all&state=merged&label_name[]=Service%3A%3AGitaly)

## Possible Resolutions

- [Previous Incidents](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/?sort=created_date&state=all&label_name%5B%5D=a%3ASidekiqQueueTooLarge&first_page_size=20)
  - [Large amount of Sidekiq Queued jobs in the elasticsearch queue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18052)
  - [SidekiqQueueTooLarge default queue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17294)

# Escalation

- Slack channels where help is likely to be found: `#g_scalability`

# Related Links

- [Related alerts](./)
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)
