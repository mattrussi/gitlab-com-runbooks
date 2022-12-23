local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-ratelimiting', cluster=false)
.overviewTrailer()
