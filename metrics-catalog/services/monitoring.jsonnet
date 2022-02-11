local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local combined = metricsCatalog.combined;
local histogramApdex = metricsCatalog.histogramApdex;
local gaugeMetric = metricsCatalog.gaugeMetric;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

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

  local defaultSelector = {
    type: 'monitoring',
    shard: 'default',
  },

  serviceLevelIndicators: {
    thanos_query: {
      // Don't count here, as we're including the total from `thanos_query_frontend`
      // which might not reach here if there was a cache hit.
      serviceAggregation: false,
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        Thanos query gathers the data needed to evaluate Prometheus queries from multiple underlying prometheus and thanos instances.
        This SLI monitors the Thanos query HTTP interface. 5xx responses are considered failures.
      |||,

      local thanosQuerySelector = defaultSelector {
        job: 'thanos-query',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQuerySelector,
        toleratedThreshold=30,
        satisfiedThreshold=9,
        metricsFormat='migrating'  // floats as `le`.
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^2.*' } },
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQuerySelector { code: { re: '^5.*' } }
      ),

      // 'handler', 'code', 'method' would be handy here. But that will change
      // the recording rule used by web/api/git which we might want to avoid.
      significantLabels: [],

      toolingLinks: [
        toolingLinks.elasticAPM(service='thanos'),
      ],
    },

    thanos_query_frontend: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos frontend sits in front of thanos query. It can act as a caching layer
        and can potentially split queries to be executed separatly.
      |||,

      local thanosQueryFrontendSelector = defaultSelector {
        job: 'thanos-query-frontend',
      },

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=thanosQueryFrontendSelector { code: { re: '^2.*' } },
        satisfiedThreshold=30,
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQueryFrontendSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=thanosQueryFrontendSelector { code: { re: '^5.*' } }
      ),

      significantLabels: [],

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
      // Don't include this in the total RPS, that would be double counting what thanos query does
      serviceAggregation: false,
      featureCategory: 'not_owned',
      description: |||
        Thanos store will respond to Thanos Query (and other) requests for historical data. This historical data is kept in
        GCS buckets. This SLI monitors the Thanos StoreAPI GRPC endpoint. GRPC error responses are considered to be service-level failures.
      |||,

      // Thanos store has shard=0-9|app|db|default so remove the default selector
      // for shard
      local thanosStoreSelector = selectors.without(defaultSelector, ['shard']) {
        job: { re: 'thanos|thanos-store(-[0-9]+)?' },
        grpc_service: 'thanos.Store',
      },

      apdex: combined([
        histogramApdex(
          histogram='grpc_server_handling_seconds_bucket',
          selector=thanosStoreSelector { grpc_type: 'unary' },
          satisfiedThreshold=0.01,
          toleratedThreshold=0.3,
          metricsFormat='migrating'
        ),
        histogramApdex(
          histogram='grpc_server_handling_seconds_bucket',
          selector=thanosStoreSelector { grpc_type: 'server_stream' },
          satisfiedThreshold=1,
          toleratedThreshold=3,
          metricsFormat='migrating'
        ),
      ]),

      requestRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector
      ),

      errorRate: rateMetric(
        counter='grpc_server_handled_total',
        selector=thanosStoreSelector { grpc_code: { ne: 'OK' } }
      ),

      significantLabels: ['grpc_type', 'grpc_method'],

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

      requestRate: rateMetric(
        counter='thanos_compact_group_compactions_total',
        selector=defaultSelector
      ),

      errorRate: rateMetric(
        counter='thanos_compact_group_compactions_failures_total',
        selector=defaultSelector
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


      requestRate: rateMetric(
        counter='thanos_alert_sender_alerts_sent_total',
        selector=defaultSelector
      ),

      errorRate: rateMetric(
        counter='thanos_alert_sender_alerts_dropped_total',
        selector=defaultSelector
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.elasticAPM(service='thanos'),
        toolingLinks.kibana(title='Thanos Rule', index='monitoring_ops', tag='monitoring.systemd.thanos-rule'),
      ],
    },

    // This component represents the Google Load Balancer in front
    // of the public Grafana instance at dashboards.gitlab.com
    public_grafana_google_lb: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=false,
      loadBalancerName='ops-dashboards-com',
      projectId='gitlab-ops',
      ignoreTrafficCessation=true
    ),

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

      // Thanos is in the default shard, the promehteus rules are spread over
      // multiple shards.
      local rulesSelector = selectors.without(defaultSelector, ['shard']),

      requestRate: rateMetric(
        counter='prometheus_rule_evaluations_total',
        selector=rulesSelector,
      ),

      errorRate: rateMetric(
        counter='prometheus_rule_evaluation_failures_total',
        selector=rulesSelector,
      ),

      // Job allows us to see if it was thanos or prometheus
      // rule group tells us which rule evaluation
      significantLabels: ['fqdn', 'job', 'rule_group'],
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

    thanos_memcached: {
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'not_owned',
      ignoreTrafficCessation: true,

      description: |||
        Various memcached instances support our thanos infrastructure, for the
        store and query-frontend components.
      |||,


      apdex: histogramApdex(
        histogram='thanos_memcached_operation_duration_seconds_bucket',
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1,
        selector=defaultSelector,
        metricsFormat='migrating'
      ),

      requestRate: rateMetric(
        counter='thanos_memcached_operations_total',
        selector=defaultSelector,
      ),

      errorRate: rateMetric(
        counter='thanos_memcached_operation_failures_total',
        selector=defaultSelector,
      ),

      significantLabels: ['fqdn', 'operation', 'reason'],
    },

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
