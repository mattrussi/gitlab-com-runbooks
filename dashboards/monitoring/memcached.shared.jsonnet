local memcachedMixin = (import 'github.com/grafana/jsonnet-libs/memcached-mixin/mixin.libsonnet');

local dashboards = memcachedMixin {
  _config+:: {
    namespace: 'default',
  },
}.grafanaDashboards;


std.foldl(
  function(memo, name)
    local uid = 'thanos-' + std.strReplace(name, '.json', '');

    memo {
      [uid]: dashboards[name] {
        title: 'Thanos: ' + dashboards[name].title,
      },
    },
  std.objectFields(dashboards),
  {}
)
