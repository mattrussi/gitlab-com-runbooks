local validator = import 'utils/validator.libsonnet';

local validateExpression(exp) =
  if std.isString(exp) then
    false
  else if std.isObject(exp) then
    !std.objectHas(exp, 'eq')
  else if std.isArray(exp) then
    std.all([validateExpression(e) for e in exp]);

// { route: 'a' }              => false
// { route: { eq: 'a' } }      => false
// { route: ['a'] }            => false
// { route: [ { eq: 'a' } ] }  => false
local validateRegexMatch(selector) =
  if !std.isObject(selector) then
    false
  else
    std.foldl(
      function(memo, label)
        validateExpression(selector[label]),
      std.objectFields(selector),
      true
    );

local metricValidator = validator.new({
  selector: validator.validator(
    validateRegexMatch,
    |||
      Selector in form of { label: "value" } or { label: { eq: "value" } } is not allowed.
      Transform them to regex match instead { label: { re: "value" } } and escape any special character with "\\"
    |||
  ),
});

{
  validateMetric(metric):: metricValidator.assertValid(metric),
}
