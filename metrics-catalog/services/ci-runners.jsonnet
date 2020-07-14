local metricsCatalog = import '../lib/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'ci-runners',
  tier: 'runners',
  monitoringThresholds: {
    apdexScore: 0.97,
    errorRatio: 0.995,  // 99.5% of ci-runner requests should succeed, over multiple window periods
  },
  serviceDependencies: {
    api: true,
  },
  components: {
    polling: {
      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        // Note, using `|||` avoids having to double-escape the backslashes in the selector query
        selector=|||
          route="^/api/v4/jobs/request\\z"
        |||,
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=|||
          code=~"5..", route="^/api/v4/jobs/request\\z"
        |||,
      ),
    },

    shared_runner_queues: {
      apdex: histogramApdex(
        histogram='job_queue_duration_seconds_bucket',
        selector='shared_runner="true", jobs_running_for_project=~"^(0|1|2|3|4)$"',
        satisfiedThreshold=60,
      ),

      requestRate: rateMetric(
        counter='gitlab_runner_jobs_total',
        selector='job="shared-runners"'
      ),

      errorRate: rateMetric(
        counter='gitlab_runner_failed_jobs_total',
        selector='job="shared-runners", failure_reason="runner_system_failure"'
      ),
    },

    // Trace archive jobs do not mark themselves as failed
    // when a job fails, instead they increment the job_trace_archive_failed_total counter
    // For this reason, our normal Sidekiq job monitoring doesn't alert us to these failures.
    // Instead, track this as a component of the CI service
    // https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/ci/archive_trace_service.rb
    trace_archiving_ci_jobs: {
      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_count',
        selector='worker="ArchiveTraceWorker"'
      ),

      errorRate: rateMetric(
        counter='job_trace_archive_failed_total',
      ),
    },
  },
})
