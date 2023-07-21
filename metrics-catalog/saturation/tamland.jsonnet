// Used to export all the metadata for saturation resources so that
// Tamland can use it as a file.
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';

local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

local uniqServices(saturationPoints) = std.foldl(
  function(memo, definition) std.set(memo + definition.appliesTo),
  std.objectValues(saturationPoints),
  []
);

// To reduce the size of saturation manifest, truncate raw catalog to essential fields required by Tamland.
// Service catalog is not to be confused with metrics catalog, refer to https://gitlab.com/gitlab-com/runbooks/-/tree/master/services#schema
local truncateRawCatalogService(service) =
  {
    name: service.name,
    label: service.label,
    owner: service.owner,
  };

local services(services) = {
  [service]: {
    capacityPlanning: metricsCatalog.getService(service).capacityPlanning,
  } + truncateRawCatalogService(serviceCatalog.lookupService(service))
  for service in services
};

{
  defaults: {
    environment: 'gprd',
  },
  services: services(uniqServices(saturation)),
  saturationPoints: saturation,
  shardMapping: {
    sidekiq: sidekiqHelpers.shards.listByName(),
  },
  teams: serviceCatalog.getRawCatalogTeams(),
}
