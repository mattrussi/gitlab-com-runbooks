local metrics = import '../gitlab-metrics-config.libsonnet';

/*

Tamland manifest for get-hybrid

*/

local uniqServices(saturationPoints) = std.foldl(
  function(memo, definition) std.set(memo + definition.appliesTo),
  std.objectValues(saturationPoints),
  []
);

// Returns an object with fake dashboard links for all components as a workaround
local dummyDashboardsPerComponent() =
  {
    [component]: {
      name: component,
      url: '',
    }
    for component in std.objectFields(metrics.saturationMonitoring)
  };

local services(services) = {
  [service]: {
    name: service,
    capacityPlanning: {},

    // Workaround for now as we don't know where to link to and Tamland
    // requires this information
    overviewDashboard: { name: '', url: '' },
    resourceDashboard: dummyDashboardsPerComponent(),
  }
  for service in services
};

local page(path, title, service_pattern) =
  {
    path: path,
    title: title,
    service_pattern: service_pattern,
  };

{
  'tamland/manifest.json': {
    defaults: {
      prometheus: {
        baseURL: 'http://kube-prometheus-stack-prometheus.monitoring:9090',
        defaultSelectors: {},
        serviceLabel: 'type',
        queryTemplates: {
          quantile95_1h: 'max(gitlab_component_saturation:ratio_quantile95_1h{%s})',
          quantile95_1w: 'max(gitlab_component_saturation:ratio_quantile95_1w{%s})',
          quantile99_1h: 'max(gitlab_component_saturation:ratio_quantile99_1h{%s})',
          quantile99_1w: 'max(gitlab_component_saturation:ratio_quantile99_1w{%s})',
        },
      },
    },
    services: services(uniqServices(metrics.saturationMonitoring)),
    saturationPoints: metrics.saturationMonitoring,
    shardMapping: {},
    teams: [],
    report: {
      pages: [
        page('all.md', 'All components', '.*'),
      ],
    },
  },
}
