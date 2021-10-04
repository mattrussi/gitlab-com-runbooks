local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

// Expression for upscaling an ratio
local upscaleRatioPromExpression = |||
  sum by (%(targetAggregationLabels)s) (
    sum_over_time(%(numeratorMetricName)s{%(sourceSelectorWithExtras)s}[%(burnRate)s])%(aggregationFilterExpr)s
  )
  /
  sum by (%(targetAggregationLabels)s) (
    sum_over_time(%(denominatorMetricName)s{%(sourceSelectorWithExtras)s}[%(burnRate)s])%(aggregationFilterExpr)s
  )
|||;

// Expression for upscaling a rate
// Note that unlike the ratio, a rate can be safely upscaled using
// avg_over_time
local upscaleRatePromExpression = |||
  sum by (%(targetAggregationLabels)s) (
    avg_over_time(%(metricName)s{%(sourceSelectorWithExtras)s}[%(burnRate)s])%(aggregationFilterExpr)s
  )
|||;

local joinExpr(targetAggregationSet) =
  if !std.objectHas(targetAggregationSet, 'joinSource') then
    ''
  else
    local requiredLabelsFromJoin = targetAggregationSet.joinSource.labels + [targetAggregationSet.joinSource.on];
    ' * on(%(joinOn)s) group_left(%(labels)s) (group by (%(aggregatedLabels)s) (%(metric)s))' % {
      joinOn: aggregations.serialize(targetAggregationSet.joinSource.on),
      labels: aggregations.serialize(targetAggregationSet.joinSource.labels),
      aggregatedLabels: aggregations.serialize(requiredLabelsFromJoin),
      metric: targetAggregationSet.joinSource.metric,
    };

local aggregationFilterExpr(targetAggregationSet) =
  local aggregationFilter = targetAggregationSet.aggregationFilter;

  // For service level aggregations, we need to filter out any SLIs which we don't want to include
  // in the service level aggregation.
  // These are defined in the SLI with `aggregateToService:false`
  joinExpr(targetAggregationSet) + if aggregationFilter != null then
    ' and on(component, type) (gitlab_component_service:mapping{%(selector)s})' % {
      selector: selectors.serializeHash(targetAggregationSet.selector {
        [aggregationFilter + '_aggregation']: 'yes',
      }),
    }
  else
    '';

local selectorForUpscaling(sourceAggregationSet, burnRate) =
  sourceAggregationSet.selector +
  if burnRate == '3d' then
    // No SLI has a 3d burn rate source metric. We always upscale from 1h metrics for 3d
    {}
  else
    { upscale_source: 'yes' };

// Upscale an apdex RATIO from source metrics to target at the given target burnRate
local upscaledApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local sourceSelectorWithExtras = selectorForUpscaling(sourceAggregationSet, burnRate);

  upscaleRatioPromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
    numeratorMetricName: sourceAggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true),
    denominatorMetricName: sourceAggregationSet.getApdexWeightMetricForBurnRate('1h', required=true),
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

// Upscale an error RATIO from source metrics to target at the given target burnRate
local upscaledErrorRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local sourceSelectorWithExtras = selectorForUpscaling(sourceAggregationSet, burnRate);

  upscaleRatioPromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
    numeratorMetricName: sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
    denominatorMetricName: sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

// Upscale an ops RATE from source metrics to target at the given target burnRate
local upscaledOpsRateExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local sourceSelectorWithExtras = selectorForUpscaling(sourceAggregationSet, burnRate);

  upscaleRatePromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
    metricName: sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

// Upscale an error RATE from source metrics to target at the given target burnRate
local upscaledErrorRateExpression(sourceAggregationSet, targetAggregationSet, burnRate) =
  local sourceSelectorWithExtras = selectorForUpscaling(sourceAggregationSet, burnRate);

  upscaleRatePromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(targetAggregationSet.labels),
    metricName: sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

{
  aggregationFilterExpr:: aggregationFilterExpr,
  upscaledApdexRatioExpression: upscaledApdexRatioExpression,
  upscaledErrorRatioExpression: upscaledErrorRatioExpression,
  upscaledOpsRateExpression: upscaledOpsRateExpression,
  upscaledErrorRateExpression: upscaledErrorRateExpression,
}
