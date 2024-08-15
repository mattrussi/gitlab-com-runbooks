local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local combined = metricsCatalog.combined;

 local sentryQuerySelector = {
    namespace: 'sentry',
  };

metricsCatalog.serviceDefinition(
  {
  type: 'sentry',
  tier: 'inf',

  tags: [
    // postgres tag implies the service is monitored with the postgres_exporter recipe from
    // https://gitlab.com/gitlab-cookbooks/gitlab-exporters
    'postgres',

    // postgres_with_primaries tags implies the service has primaries.
    // this is not the case for -archive and -delayed instances.
    'postgres_with_primaries',
  ],

  tenants: ['gitlab-ops'],

  monitoringThresholds: {
    apdexScore: 0.99,
    // Setting the Error SLO at 99% because we see high transaction rollback rates
    // TODO: investigate
    errorRatio: 0.99,
  },
  /*
   * Our anomaly detection uses normal distributions and the monitoring service
   * is prone to spikes that lead to a non-normal distribution. For that reason,
   * disable ops-rate anomaly detection on this service.
   */
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  serviceLevelIndicators: {

    sentry_events: {
      severity: 's3',
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Sentry is an application monitoring platform.
         This SLI monitors the sentry API. 5xx responses are considered failures.
      |||,

      local sentryQuerySelector = {
        namespace: 'sentry',
      },

      apdex: histogramApdex(
        histogram='nginx_ingress_controller_request_duration_seconds_bucket',
        selector=sentryQuerySelector,
        satisfiedThreshold=10,
      ),

      requestRate: rateMetric(
        counter='nginx_ingress_controller_requests',
        selector=sentryQuerySelector,
      ),

      errorRate: rateMetric(
        counter='nginx_ingress_controller_requests',
        selector=sentryQuerySelector { status: { re: '^5.*' } },
      ),

      significantLabels: ['api_version', 'status'],
    },

    pg_transactions:  {
      severity: 's3',
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'not_owned',
      description: |||
        Represents all SQL transactions issued to the sentry Postgres instance.
        Errors represent transaction rollbacks.
      |||,

      local baseSelector = { database_id: "gitlab-ops:sentry" },

      requestRate: rateMetric(
          counter='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count',
          selector=baseSelector,
        ),

      significantLabels: [],
      toolingLinks: [
        toolingLinks.stackdriverLogs(
          title='Stackdriver Logs: Sentry',
          project='gitlab-ops',
          queryHash={
            'resource.type': 'gce_instance',
            'labels."compute.googleapis.com/resource_name"': { contains: 'sentry' },
          },
        ),
      ],
    },

    redis_primary_server: {
      apdexSkip: 'apdex for redis is measured clientside',
      userImpacting: false,
      featureCategory: 'not_owned',
      serviceAggregation: false,
      description: |||
          Operations on the Redis primary for sentry's instance
        |||,

      requestRate: rateMetric(
        counter='redis_commands_processed_total',
        selector=sentryQuerySelector,
        instanceFilter='redis_instance_info{role="master"}'
        ),

        significantLabels: ['instance'],

        toolingLinks: [],
    },

      redis_secondary_servers: {
        apdexSkip: 'apdex for redis is measured clientside',
        userImpacting: false,  // userImpacting for data redundancy reasons
        featureCategory: 'not_owned',
        description: |||
          Operations on the Redis secondaries for the sentry instance.
        |||,

        requestRate: rateMetric(
          counter='redis_commands_processed_total',
          selector=sentryQuerySelector,
          instanceFilter='redis_instance_info{role="slave"}'
        ),

        significantLabels: ['instance'],
        serviceAggregation: false,
      },

      rabbitmq_queue: {
        severity: 's3',
        userImpacting: false,
        serviceAggregation: false,
        featureCategory: 'not_owned',
        description: |||
          Represents the size of the rabbitmq queue
        |||,

        requestRate: rateMetric(
          counter='rabbitmq_queue_messages',
          selector=sentryQuerySelector,
        ), 
        significantLabels: [],
      },
  },
  skippedMaturityCriteria: {
    'Structured logs available in Kibana': 'We are migrating our self-managed Sentry instance to the hosted one. For more information: https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/13963. Besides, Sentry logs are also available in Stackdriver.',
    'Service exists in the dependency graph': 'Sentry is an independent internal observability tool',
  },
})
