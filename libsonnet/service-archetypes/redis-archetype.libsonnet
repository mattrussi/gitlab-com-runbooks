local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

function(
  type,
  railsStorageSelector,
  descriptiveName,
  featureCategory='not_owned',
)
  local baseSelector = { type: type };
  local formatConfig = {
    descriptiveName: descriptiveName,
  };

  {
    type: type,
    tier: 'db',
    provisioning: {
      vms: true,
      kubernetes: true,
    },
    serviceIsStageless: true,  // We don't have cny stage for Redis instances

    tags: [
      // redis tag signifies that this service has redis-exporter
      'redis',
    ],

    monitoringThresholds: {
      apdexScore: 0.9999,
      errorRatio: 0.999,
    },


    kubeResources: {
      redis: {
        kind: 'Deployment',
        containers: [
          type,
        ],
      },
    },
    serviceLevelIndicators: {
      rails_redis_client: {
        userImpacting: true,
        featureCategory: featureCategory,
        description: |||
          Aggregation of all %(descriptiveName)s operations issued from the Rails codebase.
        ||| % formatConfig,
        significantLabels: ['type'],

        apdex: histogramApdex(
          histogram='gitlab_redis_client_requests_duration_seconds_bucket',
          selector=railsStorageSelector,
          satisfiedThreshold=0.5,
          toleratedThreshold=0.75,
        ),

        requestRate: rateMetric(
          counter='gitlab_redis_client_requests_total',
          selector=railsStorageSelector,
        ),

        errorRate: rateMetric(
          counter='gitlab_redis_client_exceptions_total',
          selector=railsStorageSelector,
        ),
      },

      primary_server: {
        userImpacting: true,
        featureCategory: featureCategory,
        description: |||
          Operations on the Redis primary for %(descriptiveName)s instance.
        ||| % formatConfig,

        requestRate: rateMetric(
          counter='redis_commands_processed_total',
          selector=baseSelector,
          instanceFilter='redis_instance_info{role="master"}'
        ),

        significantLabels: ['fqdn'],

        toolingLinks: [],
      },

      secondary_servers: {
        userImpacting: true,  // userImpacting for data redundancy reasons
        featureCategory: featureCategory,
        description: |||
          Operations on the Redis secondaries for the %(descriptiveName)s instance.
        ||| % formatConfig,

        requestRate: rateMetric(
          counter='redis_commands_processed_total',
          selector=baseSelector,
          instanceFilter='redis_instance_info{role="slave"}'
        ),

        significantLabels: ['fqdn'],
        serviceAggregation: false,
      },
    },
  }
