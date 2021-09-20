# Sidekiq queue migration

## Overview

As of June 2021, we use a model for our background jobs (which use
Sidekiq - see the [survival guide]) where each worker class has its own
queue. This means that we have over 400 queues that the application can
listen to. The author of Sidekiq [recommends] 'no more than a handful'
per Sidekiq process. Our largest processes (on the `catchall` shard)
have several hundred. This results in high CPU utilisation on the
redis-sidekiq server.

This document describes how we plan to migrate from the current situation. The
desired end state is to have one queue per shard.

[survival guide]: sidekiq-survival-guide-for-sres.md
[recommends]: https://github.com/mperham/sidekiq/wiki/Advanced-Options#queues

### Definitions

* A **worker** or **worker class** is a class defined in the application
  to perform some work in the background.
* A **queue** is the Redis data structure (list) where jobs for one - or
  many - workers are stored when waiting to be executed
* A **job** is an instance of a particular worker to be performed. It is
  serialised as a JSON object and placed into the relevant queue.
* A **generated queue name** is the queue name for the worker defined in
  the application. By default, this is generated from the worker name:
  `CreateNewIssueWorker` would have a queue name of `create_new_issue`.
* **Attributes** of a worker are defined in the application and describe
  characteristics of that worker that are useful for operators. The
  generated queue name is also an attribute of a worker.
* A **selector** is a way of declaring a set of workers to be matched by
  their attributes. For instance, `resource_boundary=cpu&urgency=high`
  picks CPU-bound high-urgency workers. The selector `*` matches all
  workers.
* A **routing rule** is a (selector, destination) pair, where the
  destination is either:
  * An explicit queue name, like `default`.
  * `null`, which means 'use the generated queue name for all workers
    matching this selector'.

  Routing rules are matched first to last, with matching for a given
  worker stopping at the first match.
* An **actual queue name** is the queue name for a worker once it has
  been processed by the routing rules. For example, with these routing
  rules:

  ```json
  [
    ["resource_boundary=cpu&urgency=high", null],
    ["*", "default"]
  ]
  ```

  Any CPU-bound high-urgency workers have an actual queue name matching
  their generated queue name. All other workers have an actual queue
  name of `default`.

## Migration steps

At a high level, migrating workers looks like this:

1. Choose some workers to migrate.
1. Ensure that we are listening to _both_ the generated queue name and the
   chosen actual queue name. If we are not, jobs will not be processed
   correctly.
1. Update the application configuration (in VMs and Kubernetes) to have
   a routing rule that routes those workers to the desired actual queue
   name. This has to be done for all instances of the application, as
   this configuration is used when scheduling a job.

   For example:

    ```js
    [
      ["resource_boundary=cpu&urgency=high", null], // existing configuration
      ["tags=example_tag", "default"], // new configuration; routes workers with `example_tag` to the `default` queue
      ["*", null] // existing configuration
    ]
    ```
1. [Migrate jobs] from the special scheduled and retry sets to match the
   newly-configured queue name: `gitlab-rake
   gitlab:sidekiq:migrate_jobs:retry
   gitlab:sidekiq:migrate_jobs:schedule`. This can be run anywhere that
   has the new configuration applied.
1. Wait for the generated queues for the workers to be empty.
1. Stop listening to the generated queue names for those workers.

[migrate jobs]: https://docs.gitlab.com/ee/raketasks/sidekiq_job_migration.html

## Troubleshooting

### A worker is flooding its queue

For instance, if we have `ProblemWorker` then its generated queue name
will be `problem`. We can route newly-scheduled jobs for this worker
back to `problem` by adding this as the top item in the routing rules:

```json
["name=problem", null]
```

If we want to process those jobs, we will need to spin up a new shard to
listen to `problem`. This process will look something like that in
[k8s-workloads/gitlab-com!930][new-shard] where we add a pod with the
new shard name and queue.

We could also re-route `ProblemWorker` to a different shard by doing,
say:

```json
["name=problem", "default"]
```

To make these jobs go in the `default` queue, which is handled by the
`catchall` shard.

This will not handle existing jobs in the original actual queue. We have
[an open issue][1080] to address this.

[1080]: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1080
[new-shard]: https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/merge_requests/930

### Something else is wrong

Please do at least two of the following:

1. [Create an issue for the Scalability team][create-issue].
2. Post in #g_scalability.
3. Mention `@gitlab-org/scalability` in an issue describing the problem.

[create-issue]: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/new
