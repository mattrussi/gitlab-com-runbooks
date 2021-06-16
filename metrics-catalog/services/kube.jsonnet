local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'kube',
  tier: 'inf',
  serviceIsStageless: true,  // kube does not have a cny stage
  monitoringThresholds: {
    // TODO: add monitoring thresholds
    // apdexScore: 0.99,
    // errorRatio: 0.99,
  },
  serviceDependencies: {
  },
  provisioning: {
    kubernetes: false,  // Kubernetes isn't deployed on Kubernetes
    vms: false,
  },
  serviceLevelIndicators: {
    apiserver: {
      userImpacting: false,
      featureCategory: 'not_owned',
      team: 'delivery',
      description: |||
        The Kubernetes API server validates and configures data for the api objects which
        include pods, services, and others. The API Server services REST operations
        and provides the frontend to the cluster's shared state through which all other components
        interact.

        This SLI measures all non-health-check endpoints. Long-polling endpoints are excluded from apdex scores.
      |||,

      local baseSelector = {
        job: 'apiserver',
        scope: { ne: '' },  // scope="" is used for health check endpoints
      },

      apdex: histogramApdex(
        histogram='apiserver_request_duration_seconds_bucket',
        selector=baseSelector { verb: { ne: 'WATCH' } },  // Exclude long-polling
        satisfiedThreshold=0.5,
      ),

      requestRate: rateMetric(
        counter='apiserver_request_total',
        selector=baseSelector
      ),

      errorRate: rateMetric(
        counter='apiserver_request_total',
        selector=baseSelector { code: { re: '5..' } }
      ),

      significantLabels: ['scope', 'resources'],

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'Kubernetes Cluster Logs',
          queryHash={
            'resource.type': 'k8s_cluster',
          },
        ),
        toolingLinks.stackdriverLogs(
          'Kubernetes Cluster Warning Logs',
          queryHash={
            'resource.type': 'k8s_cluster',
            severity: { one_of: ['EMERGENCY', 'ALERT', 'CRITICAL', 'ERROR', 'WARNING'] },
          },
        ),
      ],
    },
  },
})
