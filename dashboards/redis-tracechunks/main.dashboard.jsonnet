local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local redisCommon = import 'redis_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'service_dashboard.libsonnet';
local processExporter = import 'process_exporter.libsonnet';

serviceDashboard.overview('redis-tracechunks')
.addPanels(redisCommon.clientPanels(serviceType='redis-tracechunks', startRow=1001))
.addPanel(
  row.new(title='Workload'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.workload(serviceType='redis-tracechunks', startRow=2001))
.addPanel(
  row.new(title='Redis Data'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.data(serviceType='redis-tracechunks', startRow=3001))
.addPanel(
  row.new(title='Replication'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.replication(serviceType='redis-tracechunks', startRow=4001))
.addPanel(
  row.new(title='Sentinel Processes', collapse=true)
  .addPanels(
    processExporter.namedGroup(
      'sentinel',
      {
        environment: '$environment',
        groupname: { re: 'redis-sentinel.*' },
        type: 'redis-tracechunks',
        stage: '$stage',
      },
      startRow=1
    )
  ),
  gridPos={
    x: 0,
    y: 5000,
    w: 24,
    h: 1,
  },
)
.overviewTrailer()
