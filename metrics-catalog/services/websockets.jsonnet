local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local dependOnPatroni = import 'inhibit-rules/depend_on_patroni.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';

local railsSelector = { job: 'gitlab-rails', type: 'websockets' };

metricsCatalog.serviceDefinition({
  type: 'websockets',
  tier: 'sv',

  tags: ['golang'],

  monitoringThresholds: {
    errorRatio: 0.9995,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.90,
      errorRatio: 0.9995,
    },
  },
  serviceDependencies: {
    gitaly: true,
    'redis-sidekiq': true,
    'redis-cache': true,
    redis: true,
    patroni: true,
    pgbouncer: true,
    praefect: true,
    consul: true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: true,
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      ingressSelector=null,  // Websockets does not have its own ingress
      nodeSelector={ type: 'websockets' },
    ),
  },
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
      stageMappings={
        main: { backends: ['websockets'], toolingLinks: [] },
        cny: { backends: ['canary_websockets'], toolingLinks: [] },
      },
      selector={ type: 'frontend' },
      regional=false,
      dependsOn=dependOnPatroni.sqlComponents,
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
      dependsOn: dependOnPatroni.sqlComponents,
    },
  } + sliLibrary.get('rails_request').generateServiceLevelIndicator(railsSelector, {
    toolingLinks: [
      toolingLinks.kibana(title='Rails', index='rails'),
    ],
    dependsOn: dependOnPatroni.sqlComponents,
  }),
})
