local saturationTypes = [
  import 'cloudflare_data_transfer.libsonnet',
  import 'kube_node_requests.libsonnet',
  import 'pg_table_size.libsonnet',
  import 'pg_vacuum_time_per_day.libsonnet',
  import 'pg_dead_tup_rate.libsonnet',
  import 'pg_wraparound_time.libsonnet',
];

std.foldl(
  function(memo, module)
    memo + module,
  saturationTypes,
  {}
)
