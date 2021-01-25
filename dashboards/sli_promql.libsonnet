local aggregationSets = import './aggregation-sets.libsonnet';
local multiburnFactors = import 'mwmbr/multiburn_factors.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local globalSelector = { monitor: 'global' };
local nonGlobalSelector = { monitor: { nre: 'global|' } };

local formatConfigForSelectorHash(selectorHash) =
  {
    globalSelector: selectors.serializeHash(selectorHash + globalSelector + { env: selectorHash.environment }),
    selector: selectors.serializeHash(selectorHash + nonGlobalSelector),
  };

local apdexQuery(aggregationSet, aggregationLabels, selectorHash, range=null, worstCase=true, offset=null) =
  local metric = aggregationSet.getApdexRatioMetricForBurnRate('5m');
  local selector = selectors.merge(aggregationSet.selector, selectorHash);
  local selectorWithEnv = selectors.merge(selector, { env: selectorHash.environment });

  local aggregation = if worstCase then 'min' else 'avg';
  local rangeVectorFunction = if worstCase then 'min_over_time' else 'avg_over_time';
  local offsetExpression = if offset == null then '' else ' offset ' + offset;

  local formatConfig = {
    range: range,
    metric: metric,
    selector: selectors.serializeHash(selectorWithEnv),
    rangeVectorFunction: rangeVectorFunction,
    offsetExpression: offsetExpression,
  };

  if range == null then
    |||
      %(metric)s{%(selector)s}%(offsetExpression)s
    ||| % formatConfig
  else if aggregationLabels != null then
    |||
      %(aggregation) by (aggregationLabels) (%(rangeVectorFunction)s(%(metric)s{%(selector)s}[%(range)s]%(offsetExpression)s))
    ||| % formatConfig {
      aggregationLabels: aggregations.serialize(aggregationLabels),
      aggregation: aggregation,
    }
  else
    |||
      %(rangeVectorFunction)s(%(metric)s{%(selector)s}[%(range)s]%(offsetExpression)s)
    ||| % formatConfig;

local opsRateQuery(aggregationSet, selectorHash, range=null, offset=null) =
  local metric = aggregationSet.getOpsRateMetricForBurnRate('5m');
  local selector = selectors.merge(aggregationSet.selector, selectorHash);
  local selectorWithEnv = selectors.merge(selector, { env: selectorHash.environment });

  local offsetExpression = if offset == null then '' else ' offset ' + offset;

  local formatConfig = {
    range: range,
    metric: metric,
    selector: selectors.serializeHash(selectorWithEnv),
    offsetExpression: offsetExpression,
  };

  if range == null then
    |||
      %(metric)s{%(selector)s}%(offsetExpression)s
    ||| % formatConfig
  else
    |||
      avg_over_time(%(metric)s{%(selector)s}[%(range)s]%(offsetExpression)s)
    ||| % formatConfig;

local errorRatioQuery(aggregationSet, aggregationLabels, selectorHash, range=null, clampMax=1.0, worstCase=true, offset=null) =
  local metric = aggregationSet.getErrorRatioMetricForBurnRate('5m');
  local selector = selectors.merge(aggregationSet.selector, selectorHash);
  local selectorWithEnv = selectors.merge(selector, { env: selectorHash.environment });

  local aggregation = if worstCase then 'max' else 'avg';
  local rangeVectorFunction = if worstCase then 'max_over_time' else 'avg_over_time';
  local offsetExpression = if offset == null then '' else ' offset ' + offset;

  local formatConfig = {
    range: range,
    metric: metric,
    selector: selectors.serializeHash(selectorWithEnv),
    rangeVectorFunction: rangeVectorFunction,
    offsetExpression: offsetExpression,
  };

  local expr = if range == null then
    |||
      %(metric)s{%(selector)s}%(offsetExpression)s
    ||| % formatConfig
  else if aggregationLabels != null then
    |||
      %(aggregation) by (aggregationLabels) (%(rangeVectorFunction)s(%(metric)s{%(selector)s}[%(range)s]%(offsetExpression)s))
    ||| % formatConfig {
      aggregationLabels: aggregations.serialize(aggregationLabels),
      aggregation: aggregation,
    }
  else
    |||
      %(rangeVectorFunction)s(%(metric)s{%(selector)s}[%(range)s]%(offsetExpression)s)
    ||| % formatConfig;

  |||
    clamp_max(
      %s,
      %g
    )
  ||| % [expr, clampMax];

{
  apdexQuery:: apdexQuery,
  opsRateQuery:: opsRateQuery,
  errorRatioQuery:: errorRatioQuery,

  apdex:: {
    /**
     * Returns a promql query for the given service apdex SLI
     *
     * @param selectorHash a hash selector for the service.
     * @param range a range vector duration (ie, 5m or $__interval)
     * @param worstCase whether to use `min` instead of `avg` for aggregation
     * @return a string representation of the PromQL query
     */
    serviceApdexQuery(selectorHash, range, worstCase=true)::
      apdexQuery(aggregationSets.serviceAggregatedSLIs, null, selectorHash, range, worstCase),

    /**
     * Returns a promql query a 6h error budget SLO
     *
     * @return a string representation of the PromQL query
     */
    serviceApdexDegradationSLOQuery(environmentSelectorHash, type)::
      |||
        (1 - %(burnrate_6h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{monitor="global",type="%(type)s"})))
      ||| % {
        type: type,
        burnrate_6h: multiburnFactors.burnrate_6h,
      },

    serviceApdexOutageSLOQuery(environmentSelectorHash, type)::
      |||
        (1 - %(burnrate_1h)g * (1 - avg(slo:min:events:gitlab_service_apdex:ratio{monitor="global",type="%(type)s"})))
      ||| % {
        type: type,
        burnrate_1h: multiburnFactors.burnrate_1h,
      },

    serviceApdexQueryWithOffset(selectorHash, offset)::
      apdexQuery(aggregationSets.serviceAggregatedSLIs, null, selectorHash, range=null, offset=offset),

    sliApdexQuery(selectorHash, range)::
      apdexQuery(aggregationSets.globalSLIs, null, selectorHash, range, worstCase=false),

    sliNodeApdexQuery(selectorHash, range)::
      apdexQuery(aggregationSets.globalNodeSLIs, null, selectorHash, range, worstCase=false),

    /**
     * Returns a node-level aggregation of the apdex score for a given service, for the given selector
     */
    serviceNodeApdexQuery(selectorHash, range)::
      apdexQuery(aggregationSets.serviceNodeAggregatedSLIs, null, selectorHash, range, worstCase=false),
  },

  opsRate:: {
    serviceOpsRateQuery(selectorHash, range)::
      opsRateQuery(aggregationSets.serviceAggregatedSLIs, selectorHash, range=range),

    serviceOpsRateQueryWithOffset(selectorHash, offset)::
      opsRateQuery(aggregationSets.serviceAggregatedSLIs, selectorHash, range=null, offset=offset),

    serviceOpsRatePrediction(selectorHash, sigma)::
      |||
        clamp_min(
          avg by (type) (
            gitlab_service_ops:rate:prediction{%(globalSelector)s}
            + (%(sigma)g) *
            gitlab_service_ops:rate:stddev_over_time_1w{%(globalSelector)s}
          )
          or
          (
              sum by (type) (gitlab_service_ops:rate:prediction{%(selector)s})
              + (%(sigma)g) *
              sum by (type) (gitlab_service_ops:rate:stddev_over_time_1w{%(selector)s})
          ),
          0
        )
      ||| % formatConfigForSelectorHash(selectorHash) { sigma: sigma },

    sliOpsRateQuery(selectorHash, range)::
      opsRateQuery(aggregationSets.globalSLIs, selectorHash, range=range),

    sliNodeOpsRateQuery(selectorHash, range)::
      opsRateQuery(aggregationSets.globalNodeSLIs, selectorHash, range=range),

    /**
     * Returns a node-level aggregation of the operation rate for a given service, for the given selector
     */
    serviceNodeOpsRateQuery(selectorHash, range)::
      opsRateQuery(aggregationSets.serviceNodeAggregatedSLIs, selectorHash, range=range),
  },

  errorRate:: {
    serviceErrorRateQuery(selectorHash, range, clampMax=1.0, worstCase=true)::
      errorRatioQuery(aggregationSets.serviceAggregatedSLIs, null, selectorHash, range=range, clampMax=clampMax, worstCase=worstCase),

    serviceErrorRateDegradationSLOQuery(environmentSelectorHash, type)::
      |||
        (%(burnrate_6h)g * avg(slo:max:events:gitlab_service_errors:ratio{monitor="global",type="%(type)s"}))
      ||| % {
        type: type,
        burnrate_6h: multiburnFactors.burnrate_6h,
      },

    serviceErrorRateOutageSLOQuery(environmentSelectorHash, type)::
      |||
        (%(burnrate_1h)g * avg(slo:max:events:gitlab_service_errors:ratio{monitor="global",type="%(type)s"}))
      ||| % {
        type: type,
        burnrate_1h: multiburnFactors.burnrate_1h,
      },

    serviceErrorRateQueryWithOffset(selectorHash, offset)::
      errorRatioQuery(aggregationSets.serviceAggregatedSLIs, null, selectorHash, range=null, offset=offset),

    sliErrorRateQuery(selectorHash)::
      errorRatioQuery(aggregationSets.globalSLIs, null, selectorHash, range=null),

    sliNodeErrorRateQuery(selectorHash)::
      errorRatioQuery(aggregationSets.globalNodeSLIs, null, selectorHash, range=null),

    /**
     * Returns a node-level aggregation of the service error rate for the given selector
     */
    serviceNodeErrorRateQuery(selectorHash)::
      errorRatioQuery(aggregationSets.serviceNodeAggregatedSLIs, null, selectorHash, range=null),
  },
}
