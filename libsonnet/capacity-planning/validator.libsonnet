local validator = import 'utils/validator.libsonnet';

local recordedQuantiles = [0.95, 0.99];
local capacityPlanningStrategies = std.set(
  std.foldl(
    function(memo, quantile)
      memo + ['quantile%i_1h' % [quantile * 100], 'quantile%i_1w' % [quantile * 100]],
    recordedQuantiles,
    ['exclude']
  )
);

local positiveNumber = validator.validator(function(v) v >= 0, 'Number should be >= 0');

local isSaturationDimension(v) =
  local isDimensionObject(obj) =
    std.isObject(obj) &&
    std.isString(std.get(obj, 'selector')) &&
    std.isString(std.get(obj, 'label'));

  std.isArray(v) && std.all(std.map(function(elem) std.isString(elem) || isDimensionObject(elem), v));

local dimensionValidator = validator.validator(isSaturationDimension, 'expected an array[string] or an object[label: string, selector: string]');

{
  capacityPlanning: {
    strategy: validator.optional(validator.setMember(capacityPlanningStrategies)),
    forecast_days: validator.optional(positiveNumber),
    historical_days: validator.optional(positiveNumber),
    changepoints_count: validator.optional(positiveNumber),
    saturation_dimensions: validator.optional(dimensionValidator),
    saturation_dimensions_keep_aggregate: validator.optional(validator.boolean),
  },
}
