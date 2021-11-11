local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local perFeatureCategoryRecordingRules = (import './lib/puma-per-feature-category-recording-rules.libsonnet').perFeatureCategoryRecordingRules;
local sliLibrary = import 'gitlab-slis/library.libsonnet';

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
    'redis-tracechunks': true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    pvs: true,
    search: true,
    consul: true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: true,
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
      team='sre_coreinfra',
      stageMappings={
        main: {
          backends: ['api', 'api_rate_limit'],
          toolingLinks: [
            toolingLinks.bigquery(title='Main-stage: top paths for 5xx errors', savedQuery='805818759045:342973e81d4a481d8055b43564d09728'),
          ],
        },
        cny: { backends: ['canary_api'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
      regional=false,
    ),

    nginx_ingress: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
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

      significantLabels: ['method', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-api'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='api', slowRequestSeconds=10),
      ],
    },

    local railsSelector = { job: 'gitlab-rails', type: 'api' },
    puma: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_coreinfra',
      description: |||
        This SLI monitors API traffic in aggregate, in the GitLab rails monolith, via its
        HTTP interface. 5xx responses are treated as failures.
      |||,

      apdex: histogramApdex(
        histogram='http_request_duration_seconds_bucket',
        selector=railsSelector,
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=railsSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method', 'feature_category'],

      toolingLinks: [
        toolingLinks.sentry(slug='gitlab/gitlabcom', type='api', variables=['environment', 'stage']),
        toolingLinks.kibana(title='Rails', index='rails_api', type='api', slowRequestSeconds=10),
      ],
    },

    rails_requests:
      sliLibrary.get('rails_request_apdex').generateServiceLevelIndicator(railsSelector) {
        monitoringThresholds+: {
          apdexScore: 0.985,
        },
      },
  },
  extraRecordingRulesPerBurnRate: [
    // Adds per-feature-category plus error rates across multiple burn rates
    perFeatureCategoryRecordingRules({ type: 'api' }),
  ],
})
