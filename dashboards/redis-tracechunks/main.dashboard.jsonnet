local redisCommon = import 'gitlab-dashboards/redis_common_graphs.libsonnet';

redisCommon.redisDashboard('redis-tracechunks', cluster=false, useTimeSeriesPlugin=true)
.overviewTrailer()
