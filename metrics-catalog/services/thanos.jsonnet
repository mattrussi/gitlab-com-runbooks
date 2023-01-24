local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local gaugeMetric = metricsCatalog.gaugeMetric;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'thanos',
  tier: 'inf',

  tags: ['thanos'],

  monitoringThresholds: {
    //apdexScore: 0.999,
    //errorRatio: 0.999,
  },
  /*
   * Our anomaly detection uses normal distributions and the monitoring service
   * is prone to spikes that lead to a non-normal distribution. For that reason,
   * disable ops-rate anomaly detection on this service.
   */
  disableOpsRatePrediction: true,
  provisioning: {
    kubernetes: true,
    vms: true,
  },
  kubeResources: {
    'thanos-query': {
      kind: 'Deployment',
      containers: [
        'thanos-query',
      ],
    },
    'thanos-query-frontend': {
      kind: 'Deployment',
      containers: [
        'thanos-query-frontend',
      ],
    },
    'thanos-store': {
      kind: 'StatefulSet',
      containers: [
        'thanos-store',
      ],
    },
    'memcached-thanos-qfe-query-range': {
      kind: 'StatefulSet',
      containers: [
        'memcached',
      ],
    },
    'memcached-thanos-qfe-labels': {
      kind: 'StatefulSet',
      containers: [
        'memcached',
      ],
    },
    'memcached-thanos-bucket-cache': {
      kind: 'StatefulSet',
      containers: [
        'memcached',
      ],
    },
    'memcached-thanos-index-cache': {
      kind: 'StatefulSet',
      containers: [
        'memcached',
      ],
    },
  },
  serviceLevelIndicators: {
    thanos_query: {
      monitoringThresholds: {
        //apdexScore: 0.95,
        //errorRatio: 0.95,
      },
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos query gathers the data needed to evaluate Prometheus queries from multiple underlying prometheus and thanos instances.
        This SLI monitors the Thanos query HTTP interface. 5xx responses are considered failures.
      |||,

      local thanosQuerySelector = {
        job: 'thanos-query',
        type: 'thanos',
        shard: 'default',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        satisfiedThreshold=30,
        metricsFormat='openmetrics'
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['pod'],
    },

    thanos_query_frontend: {
      monitoringThresholds: {
        apdexScore: 0.95,
        errorRatio: 0.95,
      },
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos query gathers the data needed to evaluate Prometheus queries from multiple underlying prometheus and thanos instances.
        This SLI monitors the Thanos query HTTP interface. 5xx responses are considered failures.
      |||,

      local thanosQuerySelector = {
        job: 'thanos-query-frontend',
        type: 'thanos',
        shard: 'default',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        satisfiedThreshold=30,
        metricsFormat='openmetrics'
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['pod'],

      toolingLinks: [
        //toolingLinks.kibana(title='Thanos Query', index='monitoring_ops', tag='monitoring.systemd.thanos-query'),
      ],
    },

    thanos_store: {
      monitoringThresholds: {
        //apdexScore: 0.95,
        //errorRatio: 0.95,
      },
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos store will respond to Thanos Query (and other) requests for historical data. This historical data is kept in
        GCS buckets. This SLI monitors the Thanos StoreAPI GRPC endpoint. GRPC error responses are considered to be service-level failures.
      |||,

      local thanosStoreSelector = {
        job: { re: 'thanos-store(-[0-9]+)?' },
        type: 'thanos',
        grpc_type: 'unary',
      },

      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector=thanosStoreSelector,
        satisfiedThreshold=1,
        toleratedThreshold=3,
        metricsFormat='openmetrics'
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector { grpc_code: { ne: 'OK' } }
      ),

      significantLabels: ['pod'],

      toolingLinks: [
        toolingLinks.kibana(title='Thanos Store (gprd)', index='monitoring_gprd', tag='monitoring.systemd.thanos-store'),
        toolingLinks.kibana(title='Thanos Store (ops)', index='monitoring_ops', tag='monitoring.systemd.thanos-store'),
      ],
    },

    thanos_compactor: {
      userImpacting: false,
      featureCategory: 'not_owned',
      trafficCessationAlertConfig: false,

      description: |||
        Thanos compactor is responsible for compaction of Prometheus series data into blocks, which are stored in GCS buckets.
        It also handles downsampling. This SLI monitors compaction operations and compaction failures.
      |||,

      local thanosCompactorSelector = {
        job: 'thanos',
        type: 'thanos',
      },

      requestRate: rateMetric(
        counter='thanos_compact_group_compactions_total',
        selector=thanosCompactorSelector
      ),

      errorRate: rateMetric(
        counter='thanos_compact_group_compactions_failures_total',
        selector=thanosCompactorSelector
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        //toolingLinks.kibana(title='Thanos Compact (gprd)', index='monitoring_gprd', tag='monitoring.systemd.thanos-compact'),
        //toolingLinks.kibana(title='Thanos Compact (ops)', index='monitoring_ops', tag='monitoring.systemd.thanos-compact'),
      ],
    },

    thanos_rule_alert_sender: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors alerts generated by Thanos Ruler.
        Alert delivery failure is considered a service-level failure.
      |||,

      local thanosRuleAlertsSelector = {
        job: 'thanos',
        type: 'thanos',
      },

      requestRate: rateMetric(
        counter='thanos_alert_sender_alerts_sent_total',
        selector=thanosRuleAlertsSelector
      ),

      errorRate: rateMetric(
        counter='thanos_alert_sender_errors_total',
        selector=thanosRuleAlertsSelector
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        // toolingLinks.kibana(title='Thanos Rule', index='monitoring_ops', tag='monitoring.systemd.thanos-rule'),
      ],
    },

    // This component represents rule evaluations in
    // Thanos ruler
    rule_evaluation: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors Prometheus recording rule evaluations. Recording rule evalution failures are considered to be
        service failures.
      |||,

      local selector = { type: 'thanos' },

      requestRate: rateMetric(
        counter='prometheus_rule_evaluations_total',
        selector=selector
      ),

      errorRate: rateMetric(
        counter='prometheus_rule_evaluation_failures_total',
        selector=selector
      ),

      significantLabels: ['fqdn', 'pod'],
    },

    thanos_memcached: {
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'not_owned',
      trafficCessationAlertConfig: false,

      monitoringThresholds: {
        apdexScore: 0.999,
        errorRatio: 0.95,
      },

      description: |||
        Various memcached instances support our thanos infrastructure, for the
        store and query-frontend components.
      |||,

      local selector = { type: 'thanos' },

      apdex: histogramApdex(
        histogram='thanos_memcached_operation_duration_seconds_bucket',
        satisfiedThreshold=0.5,
        selector=selector,
        metricsFormat='openmetrics'
      ),

      requestRate: rateMetric(
        counter='thanos_memcached_operations_total',
        selector=selector,
      ),

      errorRate: rateMetric(
        counter='thanos_memcached_operation_failures_total',
        selector=selector,
      ),

      significantLabels: ['operation', 'reason'],
    },
  },

  skippedMaturityCriteria: maturityLevels.skip({
    'Service exists in the dependency graph': 'Thanos is an independent internal observability tool. It fetches metrics from other services, but does not interact with them, functionally',
  }),
})
