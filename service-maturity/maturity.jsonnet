local levels = import './maturity-levels.jsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local miscUtils = import 'utils/misc.libsonnet';

local evaluateCriterion(criterion, service) =
  local evidence = criterion.evidence(service);

  {
    name: criterion.name,
    passed: miscUtils.isPresent(evidence, nullValue=null),
    evidence: evidence,
  };

// A level passes if:
// 1. It doesn't have any failures.
// 2. It has at least one pass.
//
// Nulls count as passed for item 1 because they are not implemented
// yet, but item 2 only checks implemented criteria.
local levelPassed(criteria) =
  local softPass(passed) = if passed == 'null' then true else passed;
  local passedValues = std.map(function(criterion) criterion.passed, criteria);

  miscUtils.all(softPass, std.prune(passedValues)) && miscUtils.any(softPass, std.prune(passedValues));

local evaluateLevel(level, service) =
  local criteria = std.map(function(criterion) evaluateCriterion(criterion, service), level.criteria);

  {
    name: level.name,
    passed: levelPassed(criteria),
    criteria: criteria,
  };

local evaluate(service) =
  std.map(function(level) evaluateLevel(level, service), levels.getLevels());

// TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/827
std.foldl(function(accumulator, service) accumulator { [service.type]: evaluate(service) },
          metricsCatalog.services,
          {})
