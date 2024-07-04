local selectors = import 'promql/selectors.libsonnet';

local weeklyOperationRules(aggregationSet, extraSelector) =
  local apdexSuccessRateMetric = aggregationSet.getApdexSuccessRateMetricForBurnRate('5m', required=true);
  local selector = aggregationSet.selector + extraSelector;
  local selectorWithoutEnv = selectors.without(selector, ['env']);
  [
    {
      record: 'gitlab_service_apdex:rate:avg_over_time_1w',
      expr: |||
        avg_over_time(%(apdexSuccessRateMetric)s{%(selector)s}[1w])
        unless on(tier, type)
        gitlab_service:mapping:disable_apdex_success_rate_prediction{%(selectorWithoutEnv)s}
      ||| % {
        apdexSuccessRateMetric: apdexSuccessRateMetric,
        selector: selectors.serializeHash(selector),
        selectorWithoutEnv: selectors.serializeHash(selectorWithoutEnv),
      },
    },
    {
      record: 'gitlab_service_apdex:rate:stddev_over_time_1w',
      expr: |||
        stddev_over_time(%(apdexSuccessRateMetric)s{%(selector)s}[1w])
        unless on(tier, type)
        gitlab_service:mapping:disable_apdex_success_rate_prediction{%(selectorWithoutEnv)s}
      ||| % {
        apdexSuccessRateMetric: apdexSuccessRateMetric,
        selector: selectors.serializeHash(selector),
        selectorWithoutEnv: selectors.serializeHash(selectorWithoutEnv),
      },
    },
  ];

local weeklyPredictionRules(aggregationSet, extraSelector) =
  local apdexSuccessRateMetric = aggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true);
  local selector = extraSelector + aggregationSet.selector;
  [{
    record: 'gitlab_service_apdex:rate:prediction',
    expr: |||
      quantile(0.5,
        label_replace(
          %(apdexSuccessRateMetric)s{%(selector)s} offset 10050m # 1 week - 30mins
          + delta(gitlab_service_apdex:rate:avg_over_time_1w{%(selector)s}[1w])
          , "p", "1w", "", "")
        or
        label_replace(
          %(apdexSuccessRateMetric)s{%(selector)s} offset 20130m # 2 weeks - 30mins
          + delta(gitlab_service_apdex:rate:avg_over_time_1w{%(selector)s}[2w])
          , "p", "2w", "", "")
        or
        label_replace(
          %(apdexSuccessRateMetric)s{%(selector)s} offset 30210m # 3 weeks - 30mins
          + delta(gitlab_service_apdex:rate:avg_over_time_1w{%(selector)s}[3w])
          , "p", "3w", "", "")
      )
      without (p)
    ||| % {
      apdexSuccessRateMetric: apdexSuccessRateMetric,
      selector: selectors.serializeHash(selector),
    },
  }];
{
  recordingRuleGroupsFor(service, aggregationSet, extraSelector={}): [
    {
      name: '%s apdex success rate weekly statistics: %s' % [service, extraSelector],
      interval: '5m',
      rules: weeklyOperationRules(aggregationSet, extraSelector),
    },
    {
      name: '%s apdex success rate weekly prediction values: %s' % [service, extraSelector],
      interval: '5m',
      rules: weeklyPredictionRules(aggregationSet, extraSelector),
    },
  ],
}
