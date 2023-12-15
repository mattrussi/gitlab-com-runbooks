local periodicQuery = import './periodic-query.libsonnet';
local datetime = import 'utils/datetime.libsonnet';

local now = std.extVar('current_time');

{
  cloud_cost_spend: periodicQuery.new({
    query: |||
      sum by (vendor, item, unit, feature_category) (
          increase(gitlab_cloud_cost_spend_entry_total{env="gprd"}[1h])
      )
    |||,
    time: now,
  }),
}
