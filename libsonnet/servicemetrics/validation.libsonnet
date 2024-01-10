local validator = import 'utils/validator.libsonnet';

local metricValidator = validator.new({
  selector: validator.object,
});

{
  validateMetric(metric):: metricValidator.assertValid(metric),
}
