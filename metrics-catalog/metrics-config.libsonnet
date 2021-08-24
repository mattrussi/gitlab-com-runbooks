local aggregationSets = import './aggregation-sets.libsonnet';
local allServices = import './services/all.jsonnet';

// Site-wide configuration options
{
  // In accordance with Infra OKR: https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/8024
  slaTarget:: 0.9995,

  // List of services with SLI/SLO monitoring
  monitoredServices:: allServices,

  // Hash of all aggregation sets
  aggregationSets:: aggregationSets,
}
