local periodicQuery = import './periodic-query.libsonnet';
local datetime = import 'utils/datetime.libsonnet';
local prometheus_parameters = import './periodic-query-prometheus-parameters.libsonnet';

local now = std.extVar('current_time');

local env = std.extVar('environment', 'gprd');
local stage = std.extVar('stage', 'main');

prometheus_parameters.update({
  environment: env,
  stage: stage,
});

{
  gitaly_rate_5m: periodicQuery.new({
    query: |||
      avg_over_time(gitlab_service_ops:rate_5m{${prometheus_parameters.dump}}[1h])
    |||,
    time: now,
  }),
}