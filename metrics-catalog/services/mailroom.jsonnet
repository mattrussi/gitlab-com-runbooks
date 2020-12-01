local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

metricsCatalog.serviceDefinition({
  type: 'mailroom',
  tier: 'sv',
  // monitoringThresholds: {
  //   errorRatio: 0.999,
  // },
  serviceDependencies: {
    patroni: true,
    pgbouncer: true,
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeDeployments: {
    mailroom: {
      containers: [
        'mailroom',
      ],
    },
  },
  serviceLevelIndicators: {
  },
})
