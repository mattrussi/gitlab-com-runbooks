local periodicQuery = import './periodic-query.libsonnet';
local datetime = import 'utils/datetime.libsonnet';

local now = std.extVar('current_time');

{
  cloudflare_zone_requests_total: periodicQuery.new({
    query: |||
      increase(cloudflare_zone_requests_total{}[1h])
    |||,
    time: now,
  }),
}


{
  cloudflare_zone_data_transfer_total: periodicQuery.new({
    query: |||
      increase(cloudflare_zone_bandwidth_total{}[1h])
    |||,
    time: now,
  }),
}

