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
      page('runway.md', 'Runway', std.join('|', metricsCatalog.findRunwayProvisionedServices())),
      page('ai-assisted.md', 'AI-assisted', 'ai-assisted'),
      page('search.md', 'Search', 'search'),
      page('sidekiq.md', 'Sidekiq', 'sidekiq'),
      page('saturation.md', 'Other Utilization and Saturation Forecasting', 'camoproxy|cloud-sql|consul|frontend|google-cloud-storage|jaeger|kas|mailroom|nat|nginx|plantuml|pvs|registry|sentry|vault|web-pages|woodhouse|code_suggestions|ops-gitlab-net'),
    ],
  },
}
