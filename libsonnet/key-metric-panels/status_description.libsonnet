local sliPromql = import './sli_promql.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local objects = import 'utils/objects.libsonnet';

local descriptionMappings = [
  /* 0 */
  {
    text: 'Healthy',
    color: 'black',
  },
  /* 1 */
  {
    text: 'Warning 🔥',
    color: 'orange',
  },
  /* 2 */
  {
    text: 'Warning 🔥',
    color: 'orange',
  },
  /* 3 */
  {
    text: 'Degraded 🔥',
    color: 'red',
  },
  /* 4 */
  {
    text: 'Warning 🥵',
    color: 'orange',
  },
  /* 5 */
  {
    text: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 6 */
  {
    text: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 7 */
  {
    text: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 8 */
  {
    text: 'Warning 🥵',
    color: 'orange',
  },
  /* 9 */
  {
    text: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 10 */
  {
    text: 'Warning 🔥🥵',
    color: 'orange',
  },
  /* 11 */
  {
    text: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 12 */
  {
    text: 'Degraded 🥵',
    color: 'red',
  },
  /* 13 */
  {
    text: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 14 */
  {
    text: 'Degraded 🔥🥵',
    color: 'red',
  },
  /* 15 */
  {
    text: 'Degraded 🔥🥵',
    color: 'red',
  },
];

local apdexStatusQuery(selectorHash, type, aggregationSet) =
  local metric1h = aggregationSet.getApdexRatioMetricForBurnRate('1h', required=true);
  local metric5m = aggregationSet.getApdexRatioMetricForBurnRate('5m', required=true);
  local metric6h = aggregationSet.getApdexRatioMetricForBurnRate('6h', required=true);
  local metric30m = aggregationSet.getApdexRatioMetricForBurnRate('30m', required=true);
  local allSelectors = selectorHash + aggregationSet.selector;
  |||
    sum(
      label_replace(
        vector(0) and on() (%(metric1h)s{%(selector)s}),
        "period", "na", "", ""
      )
      or
      label_replace(
        vector(1) and on () (%(metric5m)s{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_factor_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "5m", "", ""
      )
      or
      label_replace(
        vector(2) and on () (%(metric1h)s{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_factor_1h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "1h", "", ""
      )
      or
      label_replace(
        vector(4) and on () (%(metric30m)s{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_factor_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "30m", "", ""
      )
      or
      label_replace(
        vector(8) and on () (%(metric6h)s{%(selector)s} < on(tier, type) group_left() (1 - (%(burnrate_factor_6h)g * (1 - slo:min:events:gitlab_service_apdex:ratio{%(slaSelector)s})))),
        "period", "6h", "", ""
      )
    )
  ||| %
  ({

     selector: selectors.serializeHash(allSelectors),
     slaSelector: selectors.serializeHash(sliPromql.sloLabels(allSelectors)),
     metric1h: metric1h,
     metric5m: metric5m,
     metric6h: metric6h,
     metric30m: metric30m,
     burnrate_factor_1h: multiburnFactors.errorBudgetFactorFor('1h'),
     burnrate_factor_6h: multiburnFactors.errorBudgetFactorFor('6h'),
   });

local errorRateStatusQuery(selectorHash, type, aggregationSet) =
  local metric1h = aggregationSet.getErrorRatioMetricForBurnRate('1h', required=true);
  local metric5m = aggregationSet.getErrorRatioMetricForBurnRate('5m', required=true);
  local metric6h = aggregationSet.getErrorRatioMetricForBurnRate('6h', required=true);
  local metric30m = aggregationSet.getErrorRatioMetricForBurnRate('30m', required=true);
  local allSelectors = selectorHash + aggregationSet.selector;

  |||
    sum (
      label_replace(
        vector(0) and on() (%(metric1h)s{%(selector)s}),
        "period", "na", "", ""
      )
      or
      label_replace(
        vector(1) and on() (%(metric5m)s{%(selector)s} > on(tier, type) group_left() (%(burnrate_factor_1h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "5m", "", ""
      )
      or
      label_replace(
        vector(2) and on() (%(metric1h)s{%(selector)s} > on(tier, type) group_left() (%(burnrate_factor_1h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "1h", "", ""
      )
      or
      label_replace(
        vector(4) and on() (%(metric30m)s{%(selector)s} > on(tier, type) group_left() (%(burnrate_factor_6h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "30m", "", ""
      )
      or
      label_replace(
        vector(8) and on() (%(metric6h)s{%(selector)s} > on(tier, type) group_left() (%(burnrate_factor_6h)g * slo:max:events:gitlab_service_errors:ratio{%(slaSelector)s})),
        "period", "6h", "", ""
      )
    )
  ||| %
  ({
     selector: selectors.serializeHash(allSelectors),
     slaSelector: selectors.serializeHash(sliPromql.sloLabels(allSelectors)),
     metric1h: metric1h,
     metric5m: metric5m,
     metric6h: metric6h,
     metric30m: metric30m,
     burnrate_factor_1h: multiburnFactors.errorBudgetFactorFor('1h'),
     burnrate_factor_6h: multiburnFactors.errorBudgetFactorFor('6h'),
   });


local statusDescriptionPanel(legendFormat, query) =
  {
    type: 'stat',
    title: '',
    targets: [promQuery.target(query, legendFormat=legendFormat, instant=true)],
    pluginVersion: '6.6.1',
    links: [],
    options: {
      graphMode: 'none',
      colorMode: 'background',
      justifyMode: 'auto',
      fieldOptions: {
        values: false,
        calcs: [
          'lastNotNull',
        ],
        defaults: {
          thresholds: {
            mode: 'absolute',
            steps: std.mapWithIndex(
              function(index, v)
                {
                  value: index,
                  color: v.color,
                },
              descriptionMappings
            ),
          },
          mappings: [
            {
              type: 'value',
              options: objects.fromPairs(
                std.mapWithIndex(
                  function(index, v)
                    [index, v { index: index }]
                  , descriptionMappings
                )
              ),
            },
          ],
          unit: 'none',
          nullValueMode: 'connected',
          title: 'Status',
          links: [],
        },
        overrides: [],
      },
      orientation: 'vertical',
    },
  };

{
  apdexStatusDescriptionPanel(name, selectorHash, aggregationSet)::
    local query = apdexStatusQuery(selectorHash, selectorHash.type, aggregationSet=aggregationSet);
    statusDescriptionPanel(legendFormat=name + ' | Latency/Apdex', query=query),

  errorRateStatusDescriptionPanel(name, selectorHash, aggregationSet)::
    local query = errorRateStatusQuery(selectorHash, selectorHash.type, aggregationSet=aggregationSet);
    statusDescriptionPanel(legendFormat=name + ' | Errors', query=query),

}
