local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local sliLibrary = import 'gitlab-slis/library.libsonnet';
local serviceLevelIndicatorDefinition = import 'servicemetrics/service_level_indicator_definition.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'git',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  monitoringThresholds: {
    apdexScore: 0.998,
    errorRatio: 0.9995,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      // This deployment apdex target has been lowered because of
      // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6230
      // we should consider increasing it again after we have found and resolved the cause
      apdexScore: 0.999,
      errorRatio: 0.9995,
    },

    mtbf: {
      apdexScore: 0.9997,
      errorRatio: 0.9999,
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
    pvs: true,
    consul: true,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  // Git service is spread across multiple regions, monitor it as such
  regional: true,
  kubeResources: {
    'gitlab-shell': {
      kind: 'Deployment',
      containers: [
        'gitlab-shell',
      ],
    },
    'git-https': {
      kind: 'Deployment',
      containers: [
        'gitlab-workhorse',
        'webservice',
      ],
    },
  },
  serviceLevelIndicators: {
    gitlab_shell: {
      userImpacting: true,
      featureCategory: 'not_owned',
      description: |||
        We monitor GitLab shell, using HAProxy SSH connection information.
      |||,

      staticLabels: {
        tier: 'sv',
        stage: 'main',
      },

      // Unfortunately we don't have a better way of measuring this at present,
      // so we rely on HAProxy metrics
      requestRate: customRateQuery(|||
        sum by (environment) (haproxy_backend_current_session_rate{backend=~"ssh|altssh"})
      |||),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.kibana(title='GitLab Shell', index='shell'),
      ],
    },
  },
})
