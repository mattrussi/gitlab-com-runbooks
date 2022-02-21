local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'web',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9999,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.998,
      errorRatio: 0.9999,
    },

    mtbf: {
      apdexScore: 0.9993,
      errorRatio: 0.99995,
    },
  },
  serviceDependencies: {
    gitaly: true,
    'redis-ratelimiting': true,
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
  recordingRuleMetrics: [
    'http_requests_total',
  ] + sliLibrary.get('rails_request_apdex').recordingRuleMetrics,
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: true,
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      nodeSelector={ type: 'web' },

      // TODO: at present, web nodepools do not have the correct stage, shard labels
      // see https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/2247
      nodeStaticLabels={ stage: 'main' },
    ),
  },

  kubeResources: {
    web: {
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
        main: { backends: ['web', 'main_web'], toolingLinks: [] },  // What to do with `429_slow_down`?
        cny: { backends: ['canary_web'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
      regional=false,
    ),

    local workhorseWebSelector = { job: { re: 'gitlab-workhorse|gitlab-workhorse-web' }, type: 'web' },
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
        selector=workhorseWebSelector {
          route: {
            ne: [
              '^/([^/]+/){1,}[^/]+/uploads\\\\z',
              '^/-/health$',
              '^/-/(readiness|liveness)$',
              // Technically none of these git endpoints should end up in cny, but sometimes they do,
              // so exclude them from apdex
              '^/([^/]+/){1,}[^/]+\\\\.git/git-receive-pack\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/git-upload-pack\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/info/refs\\\\z',
              '^/([^/]+/){1,}[^/]+\\\\.git/gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\\\\z',
            ],
          },
        },
        satisfiedThreshold=1,
        toleratedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseWebSelector,
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=workhorseWebSelector {
          code: { re: '^5.*' },
          route: { ne: ['^/-/health$', '^/-/(readiness|liveness)$'] },
        },
      ),

      significantLabels: ['fqdn', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-web'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='web', slowRequestSeconds=10),
      ],
    },

    imagescaler: {
      userImpacting: false,
      featureCategory: 'users',
      description: |||
        The imagescaler rescales images before sending them to clients. This allows faster transmission of
        images and faster rendering of web pages.
      |||,

      apdex: histogramApdex(
        histogram='gitlab_workhorse_image_resize_duration_seconds_bucket',
        selector=workhorseWebSelector,
        satisfiedThreshold=0.2,
        toleratedThreshold=0.8
      ),

      requestRate: rateMetric(
        counter='gitlab_workhorse_image_resize_requests_total',
        selector=workhorseWebSelector,
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.kibana(title='Image Resizer', index='workhorse_imageresizer', type='web'),
      ],
    },

    local railsSelector = { job: 'gitlab-rails', type: 'web' },
    puma: {
      userImpacting: true,
      featureCategory: serviceLevelIndicatorDefinition.featureCategoryFromSourceMetrics,
      description: |||
        Aggregation of most web requests that pass through the puma to the GitLab rails monolith.
        Healthchecks are excluded.
      |||,

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
        toolingLinks.sentry(slug='gitlab/gitlabcom', type='web', variables=['environment', 'stage']),
      ],
    },

    rails_requests:
      sliLibrary.get('rails_request_apdex').generateServiceLevelIndicator(railsSelector) {
        toolingLinks: [
          toolingLinks.kibana(title='Rails', index='rails', type='web'),
        ],
      },
  },
})
