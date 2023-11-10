local recordedQuantiles = (import 'servicemetrics/resource_saturation_point.libsonnet').recordedQuantiles;

local defaults = {
  baseURL: 'https://thanos.ops.gitlab.net',
  defaultSelectors: {
    env: 'gprd',
    environment: 'gprd',
    stage: ['main', ''],
  },
  serviceLabel: 'type',
  queryTemplates: std.foldl(
    function(memo, quantile)
      local quantilePercent = quantile * 100;
      local formatConfig = { quantilePercent: quantilePercent, selectorPlaceholder: '%s' };
      memo {
        ['quantile%d_1w' % [quantilePercent]]: 'max(gitlab_component_saturation:ratio_quantile%(quantilePercent)d_1w{%(selectorPlaceholder)s})' % formatConfig,
        ['quantile%d_1h' % [quantilePercent]]: 'max(gitlab_component_saturation:ratio_quantile%(quantilePercent)d_1h{%(selectorPlaceholder)s})' % formatConfig,
      },
    recordedQuantiles,
    {}
  ),
};

{
  defaults:: defaults,
}
