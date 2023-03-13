// Used to export all the metadata for saturation resources so that
// Tamland can use it as a file.
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';
local mapping = import './tamland_service_env_mapping.libsonnet';
local saturation = import 'servicemetrics/saturation-resources.libsonnet';

{
  saturationResources: saturation,
  shardMapping: {
    sidekiq: sidekiqHelpers.shards.listByName(),
  },
  servicesEnvMapping: mapping.servicesEnvMapping(mapping.uniqServices(saturation)),
}
