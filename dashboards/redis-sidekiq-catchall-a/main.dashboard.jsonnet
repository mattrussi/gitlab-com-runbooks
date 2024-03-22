local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-sidekiq-catchall-a', cluster=false)
.overviewTrailer()
