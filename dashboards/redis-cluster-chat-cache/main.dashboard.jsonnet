local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-cluster-chat-cache', cluster=true)
.overviewTrailer()
