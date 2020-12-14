local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
local customQuery = metricsCatalog.customQuery;
local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'logging',
  tier: 'inf',
  monitoringThresholds: {
    // apdexScore: 0.999,
    errorRatio: 0.999,
  },
  serviceLevelIndicators: {
    elasticsearch_searching: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        This SLI monitors searches issued to GitLab's logging ELK instance.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='type="logging"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    elasticsearch_indexing: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        This SLI monitors log index operations to GitLab's logging ELK instance.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='type="logging"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    // This component represents the Google Load Balancer in front
    // of logs.gitlab.net instance
    kibana_googlelb: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=false,
      loadBalancerName='ops-prod-proxy',
      projectId='gitlab-ops',
    ),

    // Stackdriver component represents log messages
    // ingested in Google Stackdrive Logging in GCP
    stackdriver: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      ignoreTrafficCessation: true,

      description: |||
        This SLI monitors the total number of logs sent to GCP StackDriver logging.
      |||,

      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='stackdriver_gce_instance_logging_googleapis_com_log_entry_count',
      ),

      significantLabels: ['log', 'severity'],
    },

    // This component tracks fluentd log output
    // across the entire fleet
    fluentd_log_output: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'sre_observability',
      description: |||
        This SLI monitors fluentd log output and the number of output errors in fluentd.
      |||,

      staticLabels: {
        stage: 'main',
      },

      requestRate: rateMetric(
        counter='fluentd_output_status_write_count',
      ),

      errorRate: rateMetric(
        counter='fluentd_output_status_num_errors'
      ),

      significantLabels: ['tag', 'type'],
      aggregateRequestRate: false,
    },
  },
})
