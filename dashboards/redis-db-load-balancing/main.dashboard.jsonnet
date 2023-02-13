local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-db-load-balancing', cluster=false, hitRatio=true)
.overviewTrailer()
