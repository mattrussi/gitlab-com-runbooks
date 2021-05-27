local toolingLinkDefinition = (import './tooling_link_definition.libsonnet').toolingLinkDefinition({ tool:: 'grafana', type:: 'dashboard' });

local mapVars(vars) =
  local varsMapped = [
    'var-%(key)s=%(value)s' % { key: key, value: vars[key] }
    for key in std.objectFields(vars)
  ];
  std.join('&', varsMapped);

local urlFromUidAndVars(dashboardUid, vars) =
  '/d/%(dashboardUid)s?%(vars)s' % {
    dashboardUid: dashboardUid,
    vars: mapVars(vars),
  };

{
  grafana(title, dashboardUid, vars={})::
    function(options)
      [
        toolingLinkDefinition({
          title: 'Grafana: ' + title,
          url: urlFromUidAndVars(dashboardUid, vars),
        }),
      ],
}
