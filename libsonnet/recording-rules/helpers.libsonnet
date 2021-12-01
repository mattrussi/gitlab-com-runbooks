local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local strings = import 'utils/strings.libsonnet';
local upscaleLabels = (import 'servicemetrics/service_level_indicator_definition.libsonnet').upscaleLabels;

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

local errorRateWithFallbackPromExpression(sourceSet, burnRate) = |||
  (%(errorRateMetricName)s{%(sourceSelector)s} or (0 * %(opsRateMetricName)s{%(sourceSelector)s}))
||| % {
  errorRateMetricName: sourceSet.getErrorRateMetricForBurnRate(burnRate, required=true),
  opsRateMetricName: sourceSet.getOpsRateMetricForBurnRate(burnRate, required=true),
  sourceSelector: selectors.serializeHash(sourceSet.selector),
};

local joinExpr(targetAggregationSet) =
  if !std.objectHas(targetAggregationSet, 'joinSource') then
    ''
  else
    local requiredLabelsFromJoin = targetAggregationSet.joinSource.labels + targetAggregationSet.joinSource.on;
    ' * on(%(joinOn)s) group_left(%(labels)s) (group by (%(aggregatedLabels)s) (%(metric)s))' % {
      joinOn: aggregations.serialize(std.set(targetAggregationSet.joinSource.on)),
      labels: aggregations.serialize(std.set(targetAggregationSet.joinSource.labels)),
      aggregatedLabels: aggregations.serialize(std.set(requiredLabelsFromJoin)),
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

local filterStaticLabelsFromAggregationLabels(aggregationLabels, staticLabels) =
  std.filter(
    function(label)
      !std.objectHas(staticLabels, label),
    aggregationLabels,
  );

// Upscale a RATIO from source metrics to target at the given target burnRate
local upscaledRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, numeratorMetricName, denominatorMetricName, staticLabels) =
  local sourceSelectorWithExtras = sourceAggregationSet.selector + staticLabels;
  local filteredAggregationLabels = filterStaticLabelsFromAggregationLabels(targetAggregationSet.labels, staticLabels);

  upscaleRatioPromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(filteredAggregationLabels),
    numeratorMetricName: numeratorMetricName,
    denominatorMetricName: denominatorMetricName,
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

// Upscale a RATE from source metrics to target at the given target burnRate
local upscaledRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, metricName, staticLabels) =
  local sourceSelectorWithExtras = sourceAggregationSet.selector + staticLabels;
  local filteredAggregationLabels = filterStaticLabelsFromAggregationLabels(targetAggregationSet.labels, staticLabels);
  upscaleRatePromExpression % {
    burnRate: burnRate,
    targetAggregationLabels: aggregations.serialize(filteredAggregationLabels),
    metricName: metricName,
    sourceSelectorWithExtras: selectors.serializeHash(sourceSelectorWithExtras),
    aggregationFilterExpr: aggregationFilterExpr(targetAggregationSet),
  };

// Upscale an apdex RATIO from source metrics to target at the given target burnRate
local upscaledApdexRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRatioExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    numeratorMetricName=sourceAggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true),
    denominatorMetricName=sourceAggregationSet.getApdexWeightMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels,
  );

// Upscale an error RATIO from source metrics to target at the given target burnRate
local upscaledErrorRatioExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRatioExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    numeratorMetricName=sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
    denominatorMetricName=sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels,
  );

// Upscale an apdex success RATE from source metrics to target at the given target burnRate
local upscaledApdexSuccessRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRateExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    metricName=sourceAggregationSet.getApdexSuccessRateMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels
  );

// Upscale an apdex total (weight) RATE from source metrics to target at the given target burnRate
local upscaledApdexWeightExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRateExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    metricName=sourceAggregationSet.getApdexWeightMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels
  );

// Upscale an ops RATE from source metrics to target at the given target burnRate
local upscaledOpsRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRateExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    metricName=sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels,
  );

// Upscale an error RATE from source metrics to target at the given target burnRate
local upscaledErrorRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  upscaledRateExpression(
    sourceAggregationSet,
    targetAggregationSet,
    burnRate,
    metricName=sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
    staticLabels=staticLabels,
  );

local upscaledSuccessRateExpression(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels) =
  local sourceMetricName = sourceAggregationSet.getSuccessRateMetricForBurnRate('1h', required=false);
  if sourceMetricName != null then
    upscaledRateExpression(
      sourceAggregationSet,
      targetAggregationSet,
      burnRate,
      metricName=sourceMetricName,
      staticLabels=staticLabels
    )
  else
    local upscaledOpsRate = strings.chomp(upscaledRateExpression(
      sourceAggregationSet,
      targetAggregationSet,
      burnRate,
      metricName=sourceAggregationSet.getOpsRateMetricForBurnRate('1h', required=true),
      staticLabels=staticLabels,
    ));
    local upscaledErrorRate = strings.chomp(upscaledRateExpression(
      sourceAggregationSet,
      targetAggregationSet,
      burnRate,
      metricName=sourceAggregationSet.getErrorRateMetricForBurnRate('1h', required=true),
      staticLabels=staticLabels,
    ));
    |||
      %(upscaledOpsRate)s
      -
      (
        %(upscaledErrorRate)s or (
          0 * %(indentedUpscaledOpsRate)s
        )
      )
    ||| % {
      upscaledOpsRate: upscaledOpsRate,
      upscaledErrorRate: strings.chomp(strings.indent(upscaledErrorRate, 2)),
      indentedUpscaledOpsRate: strings.chomp(strings.indent(upscaledOpsRate, 4)),
    };

// Generates a transformation expression that either uses direct, upscaled or
// or combines both in cases where the source expression contains a mixture
local combineUpscaleAndDirectTransformationExpressions(upscaledExprType, upscaleExpressionFn, sourceAggregationSet, targetAggregationSet, burnRate, directExpr, staticLabels) =
  // If the source is already upscaled, we can just aggregate that
  if sourceAggregationSet.upscaleBurnRate(burnRate) && directExpr != null then
    directExpr
  // For 6h burn rate, we'll use either a combination of upscaling and direct aggregation,
  // or, if the source aggregations, don't exist, only use the upscaled metric
  else if burnRate == '6h' then
    local upscaledExpr = upscaleExpressionFn(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels + upscaleLabels);

    if directExpr != null then
      |||
        (
          %(directExpr)s
        )
        or
        (
          %(upscaledExpr)s
        )
      ||| % {
        directExpr: strings.indent(directExpr, 2),
        upscaledExpr: strings.indent(upscaledExpr, 2),
      }
    else
      // If we there is no source burnRate, use only upscaling
      upscaleExpressionFn(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels)

  else if burnRate == '3d' then
    // For 3d expressions, we always use upscaling
    upscaleExpressionFn(sourceAggregationSet, targetAggregationSet, burnRate, staticLabels)
  else
    // For other burn rates, the direct expression must be used, so if it doesn't exist
    // there is a problem
    if directExpr == null then
      error 'Unable to generate a transformation expression from %(id)s for %(upscaledExprType)s for burn rate %(burnRate)s. No direct transformation is possible since source does not contain the correct expressions.' % {
        id: targetAggregationSet.id,
        upscaledExprType: upscaledExprType,
        burnRate: burnRate,
      }
    else
      directExpr;

local curry(upscaledExprType, upscaleExpressionFn) =
  function(sourceAggregationSet, targetAggregationSet, burnRate, directExpr, staticLabels={})
    combineUpscaleAndDirectTransformationExpressions(
      upscaledExprType,
      upscaleExpressionFn,
      sourceAggregationSet,
      targetAggregationSet,
      burnRate,
      directExpr,
      staticLabels
    );

{
  aggregationFilterExpr:: aggregationFilterExpr,
  errorRateWithFallbackPromExpression:: errorRateWithFallbackPromExpression,

  // These functions generate either a direct or a upscaled transformation, or a combined expression

  // Ratios
  combinedApdexRatioExpression: curry('apdexRatio', upscaledApdexRatioExpression),
  combinedErrorRatioExpression: curry('errorRatio', upscaledErrorRatioExpression),

  // Rates
  combinedApdexSuccessRateExpression: curry('apdexSuccessRate', upscaledApdexSuccessRateExpression),
  combinedApdexWeightExpression: curry('apdexWeight', upscaledApdexWeightExpression),
  combinedOpsRateExpression: curry('opsRate', upscaledOpsRateExpression),
  combinedErrorRateExpression: curry('errorRate', upscaledErrorRateExpression),
  combinedSuccessRateExpression: curry('successRate', upscaledSuccessRateExpression),
}
