local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local pgbouncerCommonGraphs = import 'pgbouncer_common_graphs.libsonnet';
local row = grafana.row;
local processExporter = import 'process_exporter.libsonnet';
local serviceDashboard = import 'service_dashboard.libsonnet';

serviceDashboard.overview('patroni')
.addPanel(
  row.new(title='pgbouncer Workload', collapse=false),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.workloadStats('patroni', 1001))
.addPanel(
  row.new(title='pgbouncer Connection Pooling', collapse=false),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.connectionPoolingPanels('patroni', 2001))
.addPanel(
  row.new(title='pgbouncer Network', collapse=false),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(pgbouncerCommonGraphs.networkStats('patroni', 3001))
.addPanel(
  row.new(title='postgres process stats', collapse=true)
  .addPanels(
    processExporter.namedGroup(
      'postgres',
      {
        environment: '$environment',
        groupname: 'postgres',
        type: 'patroni',
        stage: 'main',
      },
    )
  )
  ,
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='wal-g process stats', collapse=true)
  .addPanels(
    processExporter.namedGroup(
      'wal-g',
      {
        environment: '$environment',
        groupname: 'wal-g',
        type: 'patroni',
        stage: 'main',
      },
    )
  )
  ,
  gridPos={
    x: 0,
    y: 4010,
    w: 24,
    h: 1,
  }
)

.addPanel(
  row.new(title='patroni process stats', collapse=true)
  .addPanels(
    processExporter.namedGroup(
      'patroni',
      {
        environment: '$environment',
        groupname: 'patroni',
        type: 'patroni',
        stage: 'main',
      },
    )
  )
  ,
  gridPos={
    x: 0,
    y: 4020,
    w: 24,
    h: 1,
  }
)
.overviewTrailer()
