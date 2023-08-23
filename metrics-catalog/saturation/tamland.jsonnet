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

local page(path, title, service_pattern) =
  {
    path: path,
    title: title,
    service_pattern: service_pattern,
  };

// This is a Tamland saturation point definition
local saturationPoint(point_name, point) =
  {
    title: point['title'],
    description: point['description'],
    // ... plus all the fields relevant for Tamland at the moment

    // Depending on point.capacityPlanning.strategy, the query would look different
    // see https://gitlab.com/gitlab-com/gl-infra/tamland/-/blob/33bfe60e5f548baede075d0735af7af36e76946e/forecaster.py#L48-48
    query:'max(quantile_over_time(0.95, gitlab_component_saturation:ratio{component="' + point_name + '",type="{{ service.name }}",env="{{ defaults.env }}",environment="{{ defaults.env }}",stage=~"main|"}[1h]))',

    // Want to see the entire thing?
    //_all: point,
  };

local saturationPoints(points) = {
  [point_name]: saturationPoint(point_name, points[point_name])
  for point_name in std.objectFields(points)
};

{
  defaults: {
    environment: 'gprd',
  },
  services: services(uniqServices(saturation)),
  saturationPoints: saturationPoints(saturation),
  shardMapping: {
    sidekiq: sidekiqHelpers.shards.listByName(),
  },
  teams: serviceCatalog.getRawCatalogTeams(),
  report: {
    pages: [
      page('api-git-web.md', 'API, Git, and Web', 'api|git|internal-api|web|websockets'),
      page('ci-runners.md', 'CI Runners', 'ci-runners'),
      page('customersdot.md', 'Customersdot', 'customersdot'),
      page('gitaly.md', 'Gitaly', 'gitaly|praefect'),
      page('kube.md', 'Kubernetes', 'kube|external-dns'),
      page('monitoring-logging.md', 'Monitoring and Logging', 'monitoring|logging|thanos'),
      page('patroni.md', 'Postgres (Patroni and PgBouncer)', 'patroni.*|pgbouncer.*|postgres.*'),
      page('redis.md', 'Redis', 'redis.*'),
      page('search.md', 'Search', 'search'),
      page('sidekiq.md', 'Sidekiq', 'sidekiq'),
      page('ai-gateway.md', 'AI gateway', 'ai_gateway'),
      page('saturation.md', 'Other Utilization and Saturation Forecasting', 'camoproxy|cloud-sql|consul|frontend|google-cloud-storage|jaeger|kas|mailroom|nat|nginx|plantuml|pvs|registry|sentry|vault|web-pages|woodhouse|code_suggestions|ops-gitlab-net'),
    ],
  },
}
