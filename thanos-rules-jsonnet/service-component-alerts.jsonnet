local aggregationSets = (import 'gitlab-metrics-config.libsonnet').aggregationSets;
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';
local separateGlobalRecordingFiles = (import 'recording-rules/lib/thanos/separate-global-recording-files.libsonnet').separateGlobalRecordingFiles;
local alertGroupsForService = import 'alerts/service-component-alerts.libsonnet';

local filteredServices = std.filter(function(s) s.type != 'mimir', metricsCatalog.services);

separateGlobalRecordingFiles(
  function(selector)
    std.foldl(
      function(docs, service)
        local groups = alertGroupsForService(service, selector, aggregationSets, groupExtras={ partial_response_strategy: 'warn' });
        if groups != null then
          docs {
            ['service-level-alerts-%s' % [service.type]]: std.manifestYamlDoc(groups),
          }
        else
          docs,
      filteredServices,
      {},
    )
)
