local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-feature-flag', cluster=false, hitRatio=true)
.overviewTrailer()
