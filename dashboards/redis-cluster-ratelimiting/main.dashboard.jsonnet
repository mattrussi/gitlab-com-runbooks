local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

local serviceName = 'redis-cluster-ratelimiting';

redisCommon.redisDashboard(serviceName, cluster=true)
.overviewTrailer()
