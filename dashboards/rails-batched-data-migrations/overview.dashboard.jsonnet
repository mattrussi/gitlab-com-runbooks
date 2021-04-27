local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local platformLinks = import 'platform_links.libsonnet';
local template = grafana.template;

basic.dashboard(
  'Rails: Batched Data Migrations - Overview',
  tags=[],
  time_from='now-7d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  refresh='5m',
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Migration progress overall',
      description='Overview of all data migrations and their progress over time',
      query=|||
        max(batched_migration_migrated_tuples_total{env="$environment"}) by (migration_identifier) / avg(batched_migration_total_tuple_count{env="$environment"}) by (migration_identifier)
      |||,
      interval='1m',
      linewidth=1,
      format='percentunit',
    ),
    basic.timeseries(
      title='Rate of migrating tuples (tuples migrated per second)',
      query=|||
        sum(rate(batched_migration_job_updated_tuples_total{env="$environment"}[30m])) by (migration_identifier)
      |||,
      interval='1m',
      linewidth=1,
    ),
  ], cols=1)
)
.trailer()
