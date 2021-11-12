local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';

local baseSelector = { type: 'web-pages' };

metricsCatalog.serviceDefinition({
  type: 'web-pages',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.95,
    errorRatio: 0.05,
  },
  kubeResources: {
    'web-pages': {
      kind: 'Deployment',
      containers: [
        'gitlab-pages',
      ],
    },
  },
  monitoringThresholds: {
    apdexScore: 0.995,
    errorRatio: 0.9995,
  },
  otherThresholds: {
    mtbf: {
      apdexScore: 0.999,
      errorRatio: 0.9999,
    },
  },
  provisioning: {
    vms: true,
    kubernetes: true,
  },
  regional: true,
  serviceLevelIndicators: {
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      userImpacting=true,
      featureCategory='pages',
      stageMappings={
        main: { backends: ['pages_http'], toolingLinks: [] },
        // TODO: cny stage for pages?
      },
      selector={ type: 'pages' },
    ),

    loadbalancer_https: haproxyComponents.haproxyL4LoadBalancer(
      userImpacting=true,
      featureCategory='pages',
      stageMappings={
        main: { backends: ['pages_https'], toolingLinks: [] },
        // TODO: cny stage for pages?
      },
      selector={ type: 'pages' },
    ),

    server: {
      userImpacting: true,
      featureCategory: 'pages',
      description: |||
        Aggregation of most web requests into the GitLab Pages process.
      |||,
      // GitLab Pages sometimes serves very large files which takes some reasonable time
      // we have stricter server_headers SLI, so this threshold can be set higher
      apdex: histogramApdex(
        histogram='gitlab_pages_http_request_duration_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=10
      ),

      requestRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector=''
      ),

      errorRate: rateMetric(
        counter='gitlab_pages_http_requests_total',
        selector='code=~"5.."'
      ),

      significantLabels: ['fqdn'],

      toolingLinks: [
        toolingLinks.continuousProfiler(service='gitlab-pages'),
        toolingLinks.sentry(slug='gitlab/gitlab-pages'),
        toolingLinks.kibana(title='GitLab Pages', index='pages'),
      ],
    },

    server_headers: {
      userImpacting: true,
      featureCategory: 'pages',
      description: |||
        Response time can be slow due to large files served by pages.
        This SLI tracks only time needed to finish writing headers.
        It includes API requests to GitLab instance, scanning ZIP archive
        for file entries, processing redirects, etc.
        We use it as stricter SLI for pages as it's independent of served file size
      |||,
      apdex: histogramApdex(
        histogram='gitlab_pages_http_time_to_write_header_seconds_bucket',
        selector=baseSelector,
        satisfiedThreshold=0.5
      ),

      requestRate: rateMetric(
        counter='gitlab_pages_http_time_to_write_header_seconds_count',
        selector=baseSelector
      ),

      significantLabels: ['fqdn'],
    },
  },
})
