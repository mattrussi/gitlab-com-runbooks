local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;

basic.dashboard(
  'Batched Data Migrations - Detail',
  tags=[],
  time_from='now-7d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  refresh='5m',
)
.addTemplate(template.new(
  'migration_identifier',
  '$PROMETHEUS_DS',
  'label_values(batched_migration_migrated_tuples_total{env="$environment"}, migration_identifier)',
  refresh='load',
  sort=1,
),)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Migration progress overall',
      description='Overview of all data migrations and their progress over time',
      query=|||
        max(batched_migration_migrated_tuples_total{env="$environment", migration_identifier="$migration_identifier"}) / avg(batched_migration_total_tuple_count{env="$environment", migration_identifier="$migration_identifier"})
      |||,
      interval='1m',
      linewidth=1,
      format='percentunit',
    ),
    basic.timeseries(
      title='Rate of migrating tuples (tuples migrated per second)',
      query=|||
        sum(rate(batched_migration_job_updated_tuples_total{env="$environment", migration_identifier="$migration_identifier"}[5m]))
      |||,
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Batch size',
      query=|||
        avg(batched_migration_job_batch_size{env="$environment", migration_identifier="$migration_identifier"})
      |||,
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Sub-batch size',
      query=|||
        avg(batched_migration_job_sub_batch_size{env="$environment", migration_identifier="$migration_identifier"})
      |||,
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Interval',
      query=|||
        avg(batched_migration_job_interval_seconds{env="$environment", migration_identifier="$migration_identifier"})
      |||,
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Time Efficiency',
      query=|||
        avg(batched_migration_job_duration_seconds{env="$environment", migration_identifier="$migration_identifier"}) / avg(batched_migration_job_interval_seconds{env="$environment", migration_identifier="$migration_identifier"})
      |||,
      interval='1m',
      linewidth=1,
      format='percentunit',
    ),
    basic.timeseries(
      title='Average query time (seconds)',
      query=|||
        sum(rate(batched_migration_job_query_duration_seconds_sum{env="$environment", migration_identifier="$migration_identifier"}[5m])) / sum(rate(batched_migration_job_query_duration_seconds_count{env="$environment", migration_identifier="$migration_identifier"}[5m]))
      |||,
      interval='1m',
      linewidth=1,
    ),
    basic.timeseries(
      title='Rate of queries with execution time > 250ms',
      query=|||
        sum(rate(batched_migration_job_query_duration_seconds_bucket{env="$environment", migration_identifier="$migration_identifier", le="+Inf"}[5m]))
        -
        sum(rate(batched_migration_job_query_duration_seconds_bucket{env="$environment", migration_identifier="$migration_identifier", le="0.25"}[5m]))
      |||,
      interval='1m',
      linewidth=1,
    ),
  ], cols=2)
)
.trailer()
