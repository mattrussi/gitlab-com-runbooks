local aggregationSets = import './aggregation-sets.libsonnet';
local allServices = import './services/all.jsonnet';

// Site-wide configuration options
{
  // In accordance with Infra OKR: https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/8024
  slaTarget:: 0.9995,

  // List of services with SLI/SLO monitoring
  monitoredServices:: allServices,

  saturationMonitoring:: (import './saturation.libsonnet'),

  // Hash of all aggregation sets
  aggregationSets:: aggregationSets,

  serviceCatalog:: {
    tiers: [{ name: 'app' }],
    services: [
      {
        name: service.type,
        friendly_name: service.type,
        tier: service.tier,
      },
      for service in allServices
    ],
  },

  stageGroupMapping:: {},

  // The base selector for the environment, as configured in Grafana dashboards
  grafanaEnvironmentSelector:: { },

  // Signifies that a stage is partitioned into canary, main stage etc
  useEnvironmentStages:: false,

  // Name of the default Prometheus datasource to use
  defaultPrometheusDatasource: 'default'
}
