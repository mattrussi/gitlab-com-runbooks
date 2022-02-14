local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local gaugeMetric = metricsCatalog.gaugeMetric;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'monitoring',
  tier: 'inf',

  tags: ['golang', 'grafana', 'prometheus', 'thanos'],

  monitoringThresholds: {
    apdexScore: 0.999,
    errorRatio: 0.999,
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
    grafana: {
      kind: 'Deployment',
      containers: [
        'grafana',
      ],
    },
    'grafana-image-renderer': {
      kind: 'Deployment',
      containers: [
        'grafana-image-renderer',
      ],
    },
    'grafana-trickster': {
      kind: 'Deployment',
      containers: [
        'grafana-trickster',
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
        job: 'thanos-query',
        type: 'monitoring',
        shard: 'default',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        satisfiedThreshold=30,
        metricsFormat='migrating'
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.elasticAPM(service='thanos'),
      ],
    },

    thanos_query_frontend: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos query gathers the data needed to evaluate Prometheus queries from multiple underlying prometheus and thanos instances.
        This SLI monitors the Thanos query HTTP interface. 5xx responses are considered failures.
      |||,

      local thanosQuerySelector = {
        // The job regex was written while we were transitioning from a thanos
        // stack deployed in GCE to a new one deployed in GKE. job=thanos
        // covers all thanos components, but the metrics this filter is used for
        // are unambiguous because only the query component exposes them - in
        // the old stack.
        // In the new stack, we include the query frontend component, which we'd
        // prefer to measure from.
        // The generated rules always retain the "stage" label, which is used to
        // distinguish between the 2 stacks, so the metrics are never blended:
        // each job name is only present in one stack.
        job: { re: 'thanos|thanos-query-frontend' },
        type: 'monitoring',
        shard: 'default',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        satisfiedThreshold=30,
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.elasticAPM(service='thanos'),
        toolingLinks.kibana(title='Thanos Query', index='monitoring_ops', tag='monitoring.systemd.thanos-query'),
      ],
    },

    thanos_store: {
      monitoringThresholds: {
        apdexScore: 0.95,
        errorRatio: 0.95,
      },
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos store will respond to Thanos Query (and other) requests for historical data. This historical data is kept in
        GCS buckets. This SLI monitors the Thanos StoreAPI GRPC endpoint. GRPC error responses are considered to be service-level failures.
      |||,

      local thanosStoreSelector = {
        // Similar to the query selector above, we must pull data from jobs
        // corresponding to the old and new thanos stacks, which are mutually
        // exclusive by stage.
        job: { re: 'thanos|thanos-store(-[0-9]+)?' },
        type: 'monitoring',
        grpc_service: 'thanos.Store',
        grpc_type: 'unary',
      },

      apdex: histogramApdex(
        histogram='grpc_server_handling_seconds_bucket',
        selector=thanosStoreSelector,
        satisfiedThreshold=1,
        toleratedThreshold=3,
        metricsFormat='migrating'
      ),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector { grpc_code: { ne: 'OK' } }
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.elasticAPM(service='thanos'),
        toolingLinks.kibana(title='Thanos Store (gprd)', index='monitoring_gprd', tag='monitoring.systemd.thanos-store'),
        toolingLinks.kibana(title='Thanos Store (ops)', index='monitoring_ops', tag='monitoring.systemd.thanos-store'),
      ],
    },

    thanos_compactor: {
      userImpacting: false,
      featureCategory: 'not_owned',
      ignoreTrafficCessation: true,

      description: |||
        Thanos compactor is responsible for compaction of Prometheus series data into blocks, which are stored in GCS buckets.
        It also handles downsampling. This SLI monitors compaction operations and compaction failures.
      |||,

      local thanosCompactorSelector = {
        job: 'thanos',
        type: 'monitoring',
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
        toolingLinks.elasticAPM(service='thanos'),
        toolingLinks.kibana(title='Thanos Compact (gprd)', index='monitoring_gprd', tag='monitoring.systemd.thanos-compact'),
        toolingLinks.kibana(title='Thanos Compact (ops)', index='monitoring_ops', tag='monitoring.systemd.thanos-compact'),
      ],
    },

    // Prometheus Alert Manager Sender operations
    prometheus_alert_sender: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors all prometheus alert notifications that are generated by AlertManager.
        Alert delivery failure is considered a service-level failure.
      |||,

      local prometheusAlertsSelector = {
        job: 'prometheus',
        type: 'monitoring',
      },

      requestRate: rateMetric(
        counter='prometheus_notifications_sent_total',
        selector=prometheusAlertsSelector
      ),

      errorRate: rateMetric(
        counter='prometheus_notifications_errors_total',
        selector=prometheusAlertsSelector
      ),

      significantLabels: ['fqdn', 'alertmanager'],
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
        type: 'monitoring',
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
        toolingLinks.elasticAPM(service='thanos'),
        toolingLinks.kibana(title='Thanos Rule', index='monitoring_ops', tag='monitoring.systemd.thanos-rule'),
      ],
    },

    // This component represents the Google Load Balancer in front
    // of the internal Grafana instance at dashboards.gitlab.net
    grafana_google_lb: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=false,
      // LB automatically created by the k8s ingress
      loadBalancerName='k8s1-08811ce6-monitoring-grafana-80-013c5091',
      targetProxyName='k8s2-ts-4zodnh0s-monitoring-grafana-lhbkv8d3',
      projectId='gitlab-ops',
      ignoreTrafficCessation=true
    ),

    prometheus: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors Prometheus instances via the HTTP interface.
        5xx responses are considered errors.
      |||,

      local prometheusSelector = {
        job: { re: 'prometheus.*', ne: 'prometheus-metamon' },
        type: 'monitoring',
      },

      apdex: histogramApdex(
        histogram='prometheus_http_request_duration_seconds_bucket',
        selector=prometheusSelector,
        satisfiedThreshold=1,
        toleratedThreshold=3
      ),

      requestRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector=prometheusSelector
      ),

      errorRate: rateMetric(
        counter='prometheus_http_requests_total',
        selector=prometheusSelector { code: { re: '^5.*' } }
      ),

      significantLabels: ['fqdn', 'handler'],

      toolingLinks: [
        toolingLinks.kibana(title='Prometheus (gprd)', index='monitoring_gprd', tag='monitoring.prometheus'),
        toolingLinks.kibana(title='Prometheus (ops)', index='monitoring_ops', tag='monitoring.prometheus'),
      ],
    },

    // This component represents rule evaluations in
    // Prometheus and thanos ruler
    rule_evaluation: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors Prometheus recording rule evaluations. Recording rule evalution failures are considered to be
        service failures.
      |||,

      local selector = { type: 'monitoring' },

      requestRate: rateMetric(
        counter='prometheus_rule_evaluations_total',
        selector=selector
      ),

      errorRate: rateMetric(
        counter='prometheus_rule_evaluation_failures_total',
        selector=selector
      ),

      significantLabels: ['fqdn'],
    },

    // Trickster is a prometheus caching layer that serves requests to our
    // Grafana instances
    grafana_trickster: {
      userImpacting: false,
      featureCategory: 'not_owned',
      ignoreTrafficCessation: true,

      description: |||
        This SLI monitors the Trickster HTTP interface.
      |||,

      apdex: histogramApdex(
        histogram='trickster_frontend_requests_duration_seconds_bucket',
        satisfiedThreshold=5,
        toleratedThreshold=20
      ),

      requestRate: rateMetric(
        counter='trickster_frontend_requests_total'
      ),

      errorRate: rateMetric(
        counter='trickster_frontend_requests_total',
        selector={ http_status: { re: '5.*' } }
      ),

      significantLabels: ['pod'],
    },

    local thanosMemcachedSLI(job) = {
      local selector = {
        job: job,
        type: 'monitoring',
      },

      userImpacting: false,
      featureCategory: 'not_owned',
      ignoreTrafficCessation: true,

      description: |||
        Various memcached instances support our thanos infrastructure, for the
        store and query-frontend components.
      |||,

      apdex: histogramApdex(
        histogram='thanos_memcached_operation_duration_seconds_bucket',
        satisfiedThreshold=1,
        selector=selector,
        metricsFormat='migrating'
      ),

      requestRate: rateMetric(
        counter='memcached_commands_total',
        selector=selector,
      ),

      errorRate: rateMetric(
        counter='thanos_memcached_operation_failures_total',
        selector=selector,
      ),

      significantLabels: ['fqdn'],
    },

    memcached_thanos_store_index: thanosMemcachedSLI('memcached-thanos-index-cache-metrics'),
    memcached_thanos_store_bucket: thanosMemcachedSLI('memcached-thanos-bucket-cache-metrics'),
    memcached_thanos_qfe_query_range: thanosMemcachedSLI('memcached-thanos-qfe-query-range-metrics'),
    memcached_thanos_qfe_labels: thanosMemcachedSLI('memcached-thanos-qfe-labels-metrics'),

    grafana_cloudsql: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Grafana uses a GCP CloudSQL instance. This SLI represents SQL transactions to that service.
      |||,

      local baseSelector = { job: 'stackdriver', database: 'grafana' },

      staticLabels: {
        tier: 'inf',
        type: 'monitoring',
      },

      requestRate: gaugeMetric(
        gauge='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count',
        selector=baseSelector
      ),

      errorRate: gaugeMetric(
        gauge='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_postgresql_transaction_count',
        selector=baseSelector {
          transaction_type: 'rollback',
        }
      ),

      significantLabels: [],
      serviceAggregation: false,
      toolingLinks: [
        toolingLinks.cloudSQL('grafana-internal-f534', project='gitlab-ops'),
        toolingLinks.cloudSQL('grafana-pre-2718', project='gitlab-pre'),
      ],
    },
  },

  skippedMaturityCriteria: maturityLevels.skip({
    'Service exists in the dependency graph': 'Thanos is an independent internal observability tool. It fetches metrics from other services, but does not interact with them, functionally',
  }),
})
