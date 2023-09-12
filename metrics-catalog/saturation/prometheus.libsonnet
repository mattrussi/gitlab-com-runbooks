local url = import 'github.com/jsonnet-libs/xtd/url.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local defaults = {
  baseURL: 'https://thanos.ops.gitlab.net',
  defaultSelectors: {
    env: 'gprd',
    stage: 'main',
  },
  serviceLabel: 'type',
};

local queryUIDefaultTab = 0;  // 0 = graph, 1 = table
local queryUIDefaultRangeInput = '6h';

local saturationQueryUrl(saturationPoint, service, shard=null, rangeInput=queryUIDefaultRangeInput, tab=queryUIDefaultTab) =
  local labelSelectors = defaults.defaultSelectors {
    [defaults.serviceLabel]: service,
    [if shard != null then 'shard']: shard,
  };
  local query = saturationPoint.query % saturationPoint.queryFormatConfig {
    aggregationLabels: std.join(',', saturationPoint.resourceLabels),
    rangeInterval: saturationPoint.getBurnRatePeriod(),
    selector: selectors.serializeHash(labelSelectors),
  };
  local exprURLEncoded = url.escapeString(query);

  '%(baseURL)s/graph?g0.expr=%(query)s&g0.tab=%(tab)s&g0.range_input=%(rangeInput)s' % {
    baseURL: defaults.baseURL,
    query: exprURLEncoded,
    tab: tab,
    rangeInput: rangeInput,
  };

{
  defaults:: defaults,
  saturationQueryUrl:: saturationQueryUrl,
}
