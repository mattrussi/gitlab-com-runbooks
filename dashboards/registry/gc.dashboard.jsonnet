local crCommon = import 'container_registry_graphs.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

basic.dashboard(
  'Garbage Collection Detail',
  tags=['container registry', 'docker', 'registry'],
)
.addTemplate(templates.gkeCluster)
.addTemplate(templates.stage)
.addTemplate(templates.namespaceGitlab)
.addTemplate(
  template.custom(
    'Deployment',
    'gitlab-registry,',
    'gitlab-registry',
    hide='variable',
  )
)
.addPanel(
  row.new(title='Task Queues'),
  gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Pending Tasks',
      description=|||
        The number of tasks pending of review.
      |||,
      query='registry_gc_queue_size{environment="$environment"}',
      legendFormat='{{ queue }}'
    ),
    basic.timeseries(
      title='Postponed Tasks',
      description=|||
        The number of tasks whose review was postponed due processing errors.
      |||,
      query='registry_gc_postpones_total{environment="$environment"}',
      legendFormat='{{ worker }}'
    ),
    basic.timeseries(
      title='Time Between Reviews',
      description=|||
        The time between task reviews. This is the workers' sleep duration
        between runs.
      |||,
      query=|||
        sum by (worker, le) (
          rate(registry_gc_sleep_duration_seconds_bucket{environment="$environment"}[$__interval])
        )
      |||,
      legendFormat='{{ worker }}',
    ),
  ], cols=4, rowHeight=5, startRow=1)
)

.addPanel(
  row.new(title='Run Counts'),
  gridPos={
    x: 0,
    y: 500,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Overall',
      description=|||
        The number of online GC runs per worker.
      |||,
      query='registry_gc_runs_total{environment="$environment"}',
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='Successful',
      description=|||
        The number of successful online GC runs per worker.
      |||,
      query='registry_gc_runs_total{error="false", environment="$environment"}',
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='Failed',
      description=|||
        The number of failed online GC runs per worker.
      |||,
      query='registry_gc_runs_total{error="true", environment="$environment"}',
      legendFormat='{{ worker }}',
    ),
    basic.singlestat(
      title='Noop',
      description=|||
        The percentage of online GC runs per worker that did not result in a
        deletion (false positives).
      |||,
      query='sum by (worker)(registry_gc_runs_total{error="false", noop="true", environment="$environment"}) / sum by (worker)(registry_gc_runs_total{error="false", environment="$environment"}) * 100',
      legendFormat='{{ worker }}',
      gaugeShow=true,
      format='percent'
    ),
  ], cols=4, rowHeight=5, startRow=501)
)

.addPanel(
  row.new(title='Run Rate'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Overall',
      description=|||
        The per-second rate of all online GC runs.
      |||,

      query='sum by (worker) (rate(registry_gc_run_duration_seconds_count{environment="$environment"}[$__interval]))',
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='Successful',
      description=|||
        The per-second rate of successful online GC runs.
      |||,

      query='sum by (worker) (rate(registry_gc_run_duration_seconds_count{environment="$environment", error="false", noop="false"}[$__interval]))',
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='Failed',
      description=|||
        The per-second rate of failed online GC runs.
      |||,

      query='sum by (worker) (rate(registry_gc_run_duration_seconds_count{environment="$environment", error="true", noop="false"}[$__interval]))',
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='Noop',
      description=|||
        The per-second rate of noop (false positive) online GC runs.
      |||,

      query='sum by (worker) (rate(registry_gc_run_duration_seconds_count{environment="$environment", error="false", noop="true"}[$__interval]))',
      legendFormat='{{ worker }}',
    ),
  ], cols=4, rowHeight=5, startRow=1001)
)

.addPanel(
  row.new(title='Run Latencies'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='P90 Overall',
      description=|||
        The estimated overal P90 latency of online GC runs.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (worker, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='P90 Successful',
      description=|||
        The estimated P90 latency of successful online GC runs.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (worker, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment", error="false", noop="false"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='P90 Failed',
      description=|||
        The estimated P90 latency of failed online GC runs.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (worker, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment", error="true", noop="false"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ worker }}',
    ),
    basic.timeseries(
      title='P90 Noop',
      description=|||
        The estimated P90 latency of noop (false positive) online GC runs.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (worker, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment", error="false", noop="true"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ worker }}',
    ),
  ], cols=4, rowHeight=5, startRow=2001)
)

.addPanel(
  row.new(title='Delete Counts'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Overall',
      description=|||
        The number of deletions during online GC.
      |||,
      query='registry_gc_deletes_total{environment="$environment"}'
    ),
    basic.timeseries(
      title='Blobs',
      description=|||
        The number of blobs deleted during online GC, per backend.
      |||,
      query='registry_gc_runs_total{artifact="blob", environment="$environment"}',
      legendFormat='{{ backend }}',
    ),
    basic.timeseries(
      title='Manifests',
      description=|||
        The number of manifests deleted during online GC, per backend.
      |||,
      query='registry_gc_runs_total{artifact="manifest", environment="$environment"}',
      legendFormat='{{ backend }}',
    ),
    basic.timeseries(
      title='Failed',
      description=|||
        The number of failed deletes during online GC, per backend and artifact.
      |||,
      query='registry_gc_runs_total{error="true", environment="$environment"}',
      legendFormat='{{ legendFormat= }} {{ backend }}',
    ),
  ], cols=4, rowHeight=5, startRow=3001)
)

.addPanel(
  row.new(title='Delete Rate'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Overall',
      description=|||
        The per-second rate of all online GC deletions.
      |||,

      query='rate(registry_gc_delete_duration_seconds_count{environment="$environment"}[$__interval])',
    ),
    basic.timeseries(
      title='Blobs',
      description=|||
        The per-second rate of online GC blob deletions.
      |||,

      query='sum by (backend) (rate(registry_gc_delete_duration_seconds_count{environment="$environment", artifact="blob"}[$__interval]))',
      legendFormat='{{ backend }}',
    ),
    basic.timeseries(
      title='Manifests',
      description=|||
        The per-second rate of online GC manifest deletions.
      |||,

      query='sum by (backend) (rate(registry_gc_delete_duration_seconds_count{environment="$environment", artifact="manifest"}[$__interval]))',
      legendFormat='{{ backend }}',
    ),
  ], cols=3, rowHeight=5, startRow=4001)
)

.addPanel(
  row.new(title='Delete Latencies'),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='P90 Overall',
      description=|||
        The estimated overal P90 latency of online GC deletions.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (le) (
            rate(registry_gc_delete_duration_seconds_bucket{environment="$environment"}[$__interval])
          )
        )
      |||
    ),
    basic.timeseries(
      title='P90 Blobs',
      description=|||
        The estimated P90 latency of online GC blob deletions.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (backend, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment", artifact="blob"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ backend }}',
    ),
    basic.timeseries(
      title='P90 Manifests',
      description=|||
        The estimated P90 latency of online GC manifest deletions.
      |||,
      query=|||
        histogram_quantile(
          0.900000,
          sum by (backend, le) (
            rate(registry_gc_run_duration_seconds_bucket{environment="$environment", artifact="manifest"}[$__interval])
          )
        )
      |||,
      legendFormat='{{ backend }}',
    ),
  ], cols=3, rowHeight=5, startRow=5001)
)

.addPanel(
  row.new(title='Storage Space'),
  gridPos={
    x: 0,
    y: 6000,
    w: 24,
    h: 1,
  }
)
.addPanels(
  layout.grid([
    basic.timeseries(
      title='Overall',
      description=|||
        The number of bytes recovered by online GC.
      |||,
      query='registry_gc_storage_deleted_bytes_total{environment="$environment"}',
      format='bytes'
    ),
    basic.timeseries(
      title='Per Media Type',
      description=|||
        The number of bytes recovered by online GC, by media type.
      |||,
      query='sum by (media_type) (registry_gc_deletes_total{environment="$environment"})',
      format='bytes',
      legendFormat='{{ media_type }}'
    ),
  ], cols=2, rowHeight=5, startRow=6001)
)
