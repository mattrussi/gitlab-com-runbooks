local saturationTypes = [
  import 'cloudflare_data_transfer.libsonnet',
  import 'pg_table_size.libsonnet',
];

std.foldl(
  function(memo, module)
    memo + module,
  saturationTypes,
  {}
)
