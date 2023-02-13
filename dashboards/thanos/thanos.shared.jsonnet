local dashboards = (
  (import 'github.com/thanos-io/thanos/mixin/mixin.libsonnet') +
  (import 'thanos-config.libsonnet')
).grafanaDashboards;

std.foldl(
  function(memo, name)
    local uid = std.strReplace(name, '.json', '');

    memo {
      [uid]: dashboards[name],
    },
  std.objectFields(dashboards),
  {}
)
