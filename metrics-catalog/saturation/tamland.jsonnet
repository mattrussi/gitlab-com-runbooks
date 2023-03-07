// Used to export all the metadata for saturation resources so that
// Tamland can use it as a file.
local saturation = import 'servicemetrics/saturation-resources.libsonnet';
local sidekiqHelpers = import 'services/lib/sidekiq-helpers.libsonnet';

{
  saturationResources: saturation,
  shardMapping: {
    sidekiq: sidekiqHelpers.shards.listByName(),
  },
}
