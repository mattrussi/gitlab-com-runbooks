local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local dependOnPatroni = import 'inhibit-rules/depend_on_patroni.libsonnet';

local railsSelector = { job: 'gitlab-rails', type: 'api' };

metricsCatalog.serviceDefinition({
  type: 'api',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.999,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.995,
      errorRatio: 0.999,
    },

    mtbf: {
      apdexScore: 0.9985,
      errorRatio: 0.9998,
    },
  },
  serviceDependencies: {
    gitaly: true,
    kas: true,
    'redis-ratelimiting': true,
    'redis-cluster-ratelimiting': true,
    'redis-tracechunks': true,
    'redis-sidekiq': true,
    'redis-cache': true,
    'redis-repository-cache': true,
    'redis-sessions': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    pvs: true,
    search: true,
    consul: true,
    'google-cloud-storage': true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  recordingRuleMetrics: (
    sliLibrary.get('graphql_query').recordingRuleMetrics
    + sliLibrary.get('global_search').recordingRuleMetrics
  ),
  regional: true,
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      nodeSelector={ type: 'api' }
    ),
  },
  kubeResources: {
    api: {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },
  serviceLevelIndicators: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      userImpacting=true,
      featureCategory='not_owned',
      stageMappings={
        main: {
          backends: ['api', 'api_rate_limit', 'main_api'],
          toolingLinks: [
            toolingLinks.bigquery(title='Main-stage: top paths for 5xx errors', savedQuery='805818759045:342973e81d4a481d8055b43564d09728'),
          ],
        },
        cny: { backends: ['canary_api'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
      regional=false,
      dependsOn=dependOnPatroni.sqlComponents,
    ),

    nginx_ingress: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        nginx for api
      |||,

      local baseSelector = { type: 'api' },

      requestRate: rateMetric(
        counter='nginx_ingress_controller_requests:labeled',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='nginx_ingress_controller_requests:labeled',
        selector=baseSelector {
          status: { re: '^5.*' },
        }
      ),

      significantLabels: ['path', 'status'],

      // TODO: Add some links here
      toolingLinks: [
      ],
      serviceAggregation: false,
      dependsOn: dependOnPatroni.sqlComponents,
    },

    workhorse: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'workhorse',
      description: |||
        Aggregation of most web requests that pass through workhorse, monitored via the HTTP interface.
        Excludes health, readiness and liveness requests. Some known slow requests, such as HTTP uploads,
        are excluded from the apdex score.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_workhorse_http_request_duration_seconds_bucket',
        // Note, using `|||` avoids having to double-escape the backslashes in the selector query
        selector=|||
          job=~"gitlab-workhorse-api|gitlab-workhorse", type="api", route!="\\A/api/v4/jobs/request\\z", route!="^/api/v4/jobs/request\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"
        |||,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job=~"gitlab-workhorse-api|gitlab-workhorse", type="api"'
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector='job=~"gitlab-workhorse-api|gitlab-workhorse", type="api", code=~"^5.*", route!="^/-/health$", route!="^/-/(readiness|liveness)$"'
      ),

      significantLabels: ['region', 'method', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-api'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='api', slowRequestSeconds=10),
      ],

      dependsOn: dependOnPatroni.sqlComponents,
    },
  } + sliLibrary.get('rails_request').generateServiceLevelIndicator(railsSelector, {
    monitoringThresholds+: {
      apdexScore: 0.99,
    },

    toolingLinks: [
      toolingLinks.kibana(title='Rails', index='rails'),
    ],
    dependsOn: dependOnPatroni.sqlComponents,
  }) + sliLibrary.get('graphql_query').generateServiceLevelIndicator(railsSelector, {
    toolingLinks: [
      toolingLinks.kibana(title='Rails', index='rails_graphql'),
    ],
    dependsOn: dependOnPatroni.sqlComponents,
  }) + sliLibrary.get('global_search').generateServiceLevelIndicator(railsSelector, {
    serviceAggregation: false,  // Don't add this to the request rate of the service
    severity: 's3',  // Don't page SREs for this SLI
  }),
})
