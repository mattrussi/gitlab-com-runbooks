local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'google-cloud-storage',
  tier: 'stor',
  monitoringThresholds: {
    apdexScore: 0.997,
    errorRatio: 0.9999,
  },
  regional: false,
  serviceLevelIndicators: {
    registry_storage: {
      userImpacting: true,
      featureCategory: 'container_registry',
      description: |||
        Aggregation of all container registry GCS storage operations.
      |||,

      apdex: histogramApdex(
        histogram='registry_storage_action_seconds_bucket',
        selector='',
        satisfiedThreshold=1
      ),

      requestRate: rateMetric(
        counter='registry_storage_action_seconds_count',
      ),

      significantLabels: ['action', 'migration_path'],
    },

    workhorse_upload: {
      userImpacting: true,
      description: |||
        Monitors the performance of file uploads from Workhorse
        to GCS.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_workhorse_object_storage_upload_time_bucket',
        selector={},
        satisfiedThreshold=25
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_object_storage_upload_requests',
        selector={ le: '+Inf' },
      ),

      // Slightly misleading, but `gitlab_workhorse_object_storage_upload_requests`
      // only records error events.
      // see https://gitlab.com/gitlab-org/gitlab/blob/master/workhorse/internal/objectstore/prometheus.go
      errorRate: rateMetric(
        counter='gitlab_workhorse_object_storage_upload_requests',
        selector={},
      ),

      significantLabels: ['type'],
    },

    pages_range_requests: {
      userImpacting: true,
      description: |||
        Monitors the latency of time-to-first-byte of HTTP range requests issued from GitLab Pages to GCS.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_pages_httprange_trace_duration_bucket',
        selector={ request_stage: 'httptrace.ClientTrace.GotFirstResponseByte' },
        satisfiedThreshold=0.5
      ),

      requestRate: rateMetric(
        counter='gitlab_pages_httprange_trace_duration_bucket',
        selector={ request_stage: 'httptrace.ClientTrace.GotFirstResponseByte', le: '+Inf' },
      ),

      significantLabels: [],
    },

  },
})
