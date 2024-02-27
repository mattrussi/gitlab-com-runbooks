local labelTaxonomy = import 'label-taxonomy/label-taxonomy.libsonnet';
local separateMimirRecordingFiles = (import 'recording-rules/lib/mimir/separate-mimir-recording-files.libsonnet').separateMimirRecordingFiles;
local utilizationMetrics = import 'servicemetrics/utilization-metrics.libsonnet';
local utilizationRules = import 'servicemetrics/utilization_rules.libsonnet';
local monitoredServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';


local l = labelTaxonomy.labels;
local environmentLabels = labelTaxonomy.labelTaxonomy(l.environmentThanos | l.tier | l.service | l.stage);

local filesForSeparateSelector(serviceUtilizationMetrics) =
  function(service, selector, _extraArgs)
    local serviceSelector = selector { type: service.type };
    utilizationRules.generateUtilizationRules(
      serviceUtilizationMetrics,
      environmentLabels=environmentLabels,
      extraSelector=serviceSelector,
      filename='utilization'
    );

local metricsAndServices = [
  [utilizationMetric, service]
  for utilizationMetric in std.objectFields(utilizationMetrics)
  for service in utilizationMetrics[utilizationMetric].appliesTo
];

local metricsByService = std.foldl(
  function(memo, tuple)
    local metricName = tuple[0];
    local serviceName = tuple[1];
    local service = std.get(memo, serviceName, {});
    memo {
      [serviceName]: service {
        [metricName]: utilizationMetrics[metricName],
      },
    },
  metricsAndServices,
  {}
);

std.foldl(
  function(memo, serviceName)
    // Declaring a mocked serviceDefinition given the serviceName
    // Why? separateMimirRecordingFiles needs a serviceDefinition (only type is needed).
    // Not all utilization metrics belong to a real service definition. For example,
    // the cloudflare_data_transfer has the service cloudflare in the appliesTo array:
    // https://gitlab.com/gitlab-com/runbooks/-/blob/fea00d14bed453dcd28981889a1be38e2358f365/metrics-catalog/utilization/cloudflare_data_transfer.libsonnet#L8.
    // However, cloudflare is not a service that can be found in our service catalog at this point in time:
    // https://gitlab.com/gitlab-com/runbooks/-/tree/fea00d14bed453dcd28981889a1be38e2358f365/metrics-catalog/services
    local foundDefinition = metricsCatalog.getServiceOptional(serviceName);
    local fakeDefinition = { type: serviceName };
    local serviceDefinition = if foundDefinition == null then
      std.trace('No service definition found for ' + serviceName, fakeDefinition)
    else
      foundDefinition;
    memo + separateMimirRecordingFiles(filesForSeparateSelector(metricsByService[serviceName]), serviceDefinition),
  std.objectFields(metricsByService),
  {}
)
