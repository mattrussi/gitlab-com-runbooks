local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;

metricsCatalog.serviceDefinition({
  type: 'gcs',
  tier: 'inf',
  serviceIsStageless: true,  // gcs does not have a cny stage
  monitoringThresholds: {
    // TODO: define thresholds for the GCS service
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },

  serviceLevelIndicators: {
    // TODO: add artifact storage for CarrierWave sidekiq jobs
    // This is blocked on https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1178
    // artifact_storage: {
    // },

    registry_storage: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_coreinfra',

      description: |||
        Measures the latency of registry service storage operations, which rely on a GCS backend.
      |||,

      apdex: histogramApdex(
        histogram='registry_storage_action_seconds_bucket',
        selector={},
        satisfiedThreshold=1
      ),

      requestRate: rateMetric(
        counter='registry_storage_action_seconds_count',
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'GCS Error Logs',
          queryHash={
            'resource.type': 'gcs_bucket',
            'resource.labels.bucket_name': { one_of: ['gitlab-gprd-registry', 'gitlab-gprd-container-registry'] },
            severity: { one_of: ['Alert', 'Critical', 'Error', 'Warning', 'Emergency'] },
          },
        ),
      ],
    },

    workhorse_uploads: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_coreinfra',

      description: |||
        Measures the latency of workhorse uploads which use a GCS bucket backend
      |||,

      apdex: histogramApdex(
        // Pity this bucket doesn't include a unit in it's name,
        // but its measured in seconds
        histogram='gitlab_workhorse_object_storage_upload_time_bucket',
        selector={},
        satisfiedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_object_storage_upload_time_bucket',
        selector={ le: '+Inf' },
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'GCS Error Logs',
          queryHash={
            'resource.type': 'gcs_bucket',
            'resource.labels.bucket_name': { one_of: ['gitlab-gprd-uploads'] },
            severity: { one_of: ['Alert', 'Critical', 'Error', 'Warning', 'Emergency'] },
          },
        ),
      ],
    },
  }
})
