# Deferring Sidekiq jobs

## Background

During an incident, some runaway worker instances could saturate infrastructure resources (database and database connection pool).
If we let these workers to keep running, the entire system performance can be significantly impacted.

## Deferring jobs using feature flags via ChatOps

We have a mechanism to defer jobs from a Worker class by enabling a feature flag `defer_sidekiq_jobs_{WorkerName}` via ChatOps.
By default, the jobs are **delayed for 5 minutes** indefinitely until the feature flag is disabled. The delay can be set via
setting environment variable `SIDEKIQ_DEFER_JOBS_DELAY` in seconds.

The implementation can be found at [DeferJobs Sidekiq server middleware](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/sidekiq_middleware/defer_jobs.rb).

More details can be found [here](https://docs.gitlab.com/ee/development/feature_flags/#deferring-sidekiq-jobs)

### Example

When the feature flag is set to true, 100% of the jobs will be deferred. Then, we can also use **percentage of time** rollout
to progressively let the jobs processed. For example:

```shell
# defer 100% of the jobs
/chatops run feature set defer_sidekiq_jobs_SlowRunningWorker true

# defer 99% of the jobs, only letting 1% processed
/chatops run feature set defer_sidekiq_jobs_SlowRunningWorker 99

# defer 50% of the jobs
/chatops run feature set defer_sidekiq_jobs_SlowRunningWorker 50

# stop deferring the jobs, jobs are being processed normally
/chatops run feature set defer_sidekiq_jobs_SlowRunningWorker false
```

To ensure we are not leaving any worker being deferred forever, check all feature flags matching `defer_sidekiq_jobs`:

```shell
/chatops run feature list --match defer_sidekiq_jobs
````

### Disabling the DeferJobs middleware

The [DeferJobs Sidekiq server middleware](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/sidekiq_middleware/defer_jobs.rb)
introduces overhead for checking feature flag first (`Feature.enabled?`) before running every job.

The overhead includes:

- 1 DB call per worker per hour ([since Redis cache TTL is 1 hour](https://gitlab.com/gitlab-org/gitlab/-/blob/47c8eca764c926ecdf0897f7b992353bb231b7c1/lib/feature.rb#L303))
- 1 Redis call per pod per worker per minute ([since thread local cache TTL is 1 minute](https://gitlab.com/gitlab-org/gitlab/-/blob/47c8eca764c926ecdf0897f7b992353bb231b7c1/lib/feature.rb#L310-310))

If the overhead turns out significantly impacting all workers performance, we can disable the middleware
by setting the environment variable `SIDEKIQ_DEFER_JOBS` to `false` or `1` and restart the Sidekiq pods.
