local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'nginx',
  tier: 'sv',
  monitoringThresholds: {
    // apdexScore: 0.995,
    // errorRatio: 0.999,
  },
  serviceDependencies: {
    api: false,
    web: false,
  },
  provisioning: {
    vms: false,
    kubernetes: true,
  },
  regional: true,
  kubeResources: {
    'gitlab-nginx': {
      kind: 'Deployment',
      containers: [
        'controller',
      ],
    },
  },
  serviceLevelIndicators: {
    nginx_ingress: {
      userImpacting: true,
      featureCategory: 'not_owned',
      team: 'delivery',
      description: |||
        nginx ingress
      |||,

      local baseSelector = { app: 'nginx-ingress' },

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

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'NGINX stderr',
          queryHash={
            'resource.type': 'k8s_container',
            'labels."k8s-pod/app"': 'nginx-ingress',
            logName: { one_of: ['projects/gitlab-production/logs/stderr', 'projects/gitlab-staging-1/logs/stderr'] },
          },
        ),
      ],
    },
  },
})
