local periodicQuery = import './periodic-query.libsonnet';
local datetime = import 'utils/datetime.libsonnet';

local now = std.extVar('current_time');

local env = std.extVar('environment', 'gprd');
local stage = std.extVar('stage', 'main');

{
  gitaly_rate_5m: periodicQuery.new({
    query: |||
      avg_over_time(gitlab_service_ops:rate_5m{
        env:        "${env}",
        stage:      "${stage}",
        monitor:    "global",
        type:       "gitaly",
      }[$__interval])
    |||,
    time: now,
  }),
}
