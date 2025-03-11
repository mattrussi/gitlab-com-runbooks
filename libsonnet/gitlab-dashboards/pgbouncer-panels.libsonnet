local pgbouncerCommonGraphs = import './pgbouncer_common_graphs.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local serviceDashboard = import './service_dashboard.libsonnet';

local pgbouncer(
  type='pgbouncer',
  user='gitlab',
  useTimeSeriesPlugin=false,
      ) =
  serviceDashboard.overview(type)
  .addPanel(
    row.new(title='pgbouncer Workload'),
    gridPos={
      x: 0,
      y: 1000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.workloadStats(type, startRow=2000, useTimeSeriesPlugin=useTimeSeriesPlugin))
  .addPanel(
    row.new(title='pgbouncer Connection Pooling'),
    gridPos={
      x: 0,
      y: 3000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.connectionPoolingPanels(type, user, 3001, useTimeSeriesPlugin=useTimeSeriesPlugin))
  .addPanel(
    row.new(title='pgbouncer Network'),
    gridPos={
      x: 0,
      y: 4000,
      w: 24,
      h: 1,
    }
  )
  .addPanels(pgbouncerCommonGraphs.networkStats(type, 4001, useTimeSeriesPlugin=useTimeSeriesPlugin))
  .addPanel(
    row.new(title='pgbouncer Client Transaction Utilisation'),
    gridPos={
      x: 0,
      y: 5000,
      w: 24,
      h: 1,
    }
  );

{
  pgbouncer:: pgbouncer,
}
