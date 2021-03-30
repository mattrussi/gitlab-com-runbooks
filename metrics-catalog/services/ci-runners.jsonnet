local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'ci-runners',
  tier: 'runners',
  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  monitoringThresholds: {
    apdexScore: 0.97,
    errorRatio: 0.995,  // 99.5% of ci-runner requests should succeed, over multiple window periods
  },
  otherThresholds: {
    mtbf: {
      apdexScore: 0.985,
      errorRatio: 0.995,
    },
  },
  serviceDependencies: {
    api: true,
  },
  serviceLevelIndicators: {
    polling: {
      userImpacting: true,
      featureCategory: 'runner',
      team: 'sre_coreinfra',
      description: |||
        This SLI monitors job polling operations from runners, via the workhorse HTTP interface.
        5xx responses are considered to be failures.
      |||,

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

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(
          title='Workhorse',
          index='workhorse',
          matches={ 'json.uri.keyword': '/api/v4/jobs/request' }
        ),
      ],
    },

    shared_runner_queues: {
      userImpacting: true,
      featureCategory: 'runner',
      team: 'sre_coreinfra',
      description: |||
        This SLI monitors the shared runner queues on GitLab.com. Each job is an operation.
        Apdex uses queueing latencies for jobs which are considered to be fair-usage (less than 5 concurrently running jobs).
        Jobs marked as failing with runner system failures are considered to be in error.
      |||,

      apdex: histogramApdex(
        histogram='job_queue_duration_seconds_bucket',
        selector='shared_runner="true", jobs_running_for_project=~"^(0|1|2|3|4)$"',
        satisfiedThreshold=60,
      ),

      requestRate: rateMetric(
        counter='gitlab_runner_jobs_total',
        selector={
          job: 'runners-manager',
          shard: 'shared',
        },
      ),

      errorRate: rateMetric(
        counter='gitlab_runner_failed_jobs_total',
        selector={
          failure_reason: 'runner_system_failure',
          job: 'runners-manager',
          shard: 'shared',
        },
      ),

      significantLabels: ['jobs_running_for_project'],

      toolingLinks: [
        toolingLinks.kibana(title='CI Runners', index='runners', slowRequestSeconds=60),
      ],
    },

    // Trace archive jobs do not mark themselves as failed
    // when a job fails, instead they increment the job_trace_archive_failed_total counter
    // For this reason, our normal Sidekiq job monitoring doesn't alert us to these failures.
    // Instead, track this as a component of the CI service
    // https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/ci/archive_trace_service.rb
    trace_archiving_ci_jobs: {
      userImpacting: true,
      featureCategory: 'continuous_integration',
      team: 'sre_coreinfra',
      description: |||
        This SLI monitors CI job archiving, via Sidekiq jobs.
      |||,

      requestRate: rateMetric(
        counter='sidekiq_jobs_completion_seconds_count',
        selector='worker="ArchiveTraceWorker"'
      ),

      errorRate: rateMetric(
        counter='job_trace_archive_failed_total',
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.grafana(title='ArchiveTraceWorker Detail', dashboardUid='sidekiq-queue-detail', vars={ queue: 'pipeline_background:archive_trace' }),
        toolingLinks.kibana(
          title='Sidekiq ArchiveTraceWorker',
          index='sidekiq',
          matches={ 'json.class.keyword': 'ArchiveTraceWorker' }
        ),
      ],
    },
  },
})
