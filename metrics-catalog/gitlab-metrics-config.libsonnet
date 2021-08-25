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

  // service_catalog.json is stored in the `services` directory
  // alongside service_catalog.yml
  serviceCatalog:: import 'service_catalog.json',

  // stage-group-mapping.jsonnet is generated file, stored in the `services` directory
  stageGroupMapping:: import 'stage-group-mapping.jsonnet',
}
