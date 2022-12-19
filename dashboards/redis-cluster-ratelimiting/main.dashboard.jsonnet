local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';
local row = grafana.row;
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local serviceName = 'redis-cluster-ratelimiting';

serviceDashboard.overview(serviceName)
.addTemplate(templates.shard)
.addPanels(redisCommon.clientPanels(serviceType=serviceName, startRow=1001, cluster=true))
.addPanel(
  row.new(title='Workload'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.workload(serviceType=serviceName, startRow=2001, cluster=true))
.addPanel(
  row.new(title='Redis Data'),
  gridPos={
    x: 0,
    y: 3000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.data(serviceType=serviceName, startRow=3001, cluster=true))
.addPanel(
  row.new(title='Replication'),
  gridPos={
    x: 0,
    y: 4000,
    w: 24,
    h: 1,
  }
)
.addPanels(redisCommon.replication(serviceType=serviceName, startRow=4001, cluster=true))
.overviewTrailer()
