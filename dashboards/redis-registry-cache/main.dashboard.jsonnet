local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-registry-cache', cluster=false, hitRatio=true)
.overviewTrailer()
