local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local perFeatureCategoryRecordingRules = (import './lib/puma-per-feature-category-recording-rules.libsonnet').perFeatureCategoryRecordingRules;

metricsCatalog.serviceDefinition({
  type: 'websockets',
  tier: 'sv',

  tags: ['golang'],

  monitoringThresholds: {
    errorRatio: 0.9995,
  },
  serviceDependencies: {
    gitaly: true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: true,
  kubeResources: {
    websockets: {
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
      team='sre_datastores',
      stageMappings={
        main: { backends: ['websockets'], toolingLinks: [] },
        cny: { backends: ['canary_websockets'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
      regional=false,
    ),

    workhorse: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'workhorse',
      description: |||
        Monitors the Workhorse instance running in the Websockets fleet, via the HTTP interface.
        This only covers the initial protocal upgrade requests to `/-/cable`.
        https://gitlab.com/gitlab-org/gitlab/-/issues/296845 tracks making these metrics more useful for Websockets.
      |||,

      local baseSelector = {
        job: 'gitlab-workhorse',
        type: 'websockets',
        route: [{ ne: '^/-/health$' }, { ne: '^/-/(readiness|liveness)$' }, { ne: '^/api/' }],
      },

      requestRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='gitlab_workhorse_http_requests_total',
        selector=baseSelector {
          code: { re: '^5.*' },
        }
      ),

      significantLabels: ['fqdn', 'route'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='workhorse-websockets'),
        toolingLinks.sentry(slug='gitlab/gitlab-workhorse-gitlabcom'),
        toolingLinks.kibana(title='Workhorse', index='workhorse', type='websockets', slowRequestSeconds=10),
      ],
    },

    puma: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'sre_datastores',
      description: |||
        Monitors Rails endpoints, running in the Git fleet, via the HTTP interface.
      |||,

      local baseSelector = { job: 'gitlab-rails', type: 'websockets' },
      requestRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector,
      ),

      errorRate: rateMetric(
        counter='http_requests_total',
        selector=baseSelector { status: { re: '5..' } }
      ),

      significantLabels: ['fqdn', 'method', 'feature_category'],

      toolingLinks: [
        // Improve sentry link once https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/532 arrives
        toolingLinks.sentry(slug='gitlab/gitlabcom', type='websockets', variables=['environment', 'stage']),
        toolingLinks.kibana(title='Rails', index='rails', type='websockets', slowRequestSeconds=10),
      ],
    },
  },
  extraRecordingRulesPerBurnRate: [
    // Adds per-feature-category plus error rates across multiple burn rates
    perFeatureCategoryRecordingRules({ type: 'websockets' }),
  ],
})
