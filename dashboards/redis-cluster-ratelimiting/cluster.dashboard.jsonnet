local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local template = grafana.template;
local templates = import 'grafana/templates.libsonnet';

basic.dashboard(
  'Cluster Info',
  tags=['cluster'],
)
.addTemplate(templates.shard)
.addPanels(redisCommon.cluster(serviceType='redis-cluster-ratelimiting', startRow=0))
