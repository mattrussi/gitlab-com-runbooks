local misc = import 'utils/misc.libsonnet';

local evaluateCriterion(criterion, service) =
  if std.objectHas(service, 'skippedMaturityCriteria') && std.member(service.skippedMaturityCriteria, criterion.name) then
    {
      name: criterion.name,
      result: 'skipped',
      evidence: [],
    }
  else
    local evidence = criterion.evidence(service);
    local result =
      if evidence == null then
        'unimplemented'
      else if misc.isPresent(evidence, nullValue=null) then
        'passed'
      else
        'failed';

    {
      name: criterion.name,
      result: result,
      evidence: evidence,
    };

// A level passes if it doesn't have any failures.
//
// Unimplemented (null) and skipped are considered to be passed. If a whole
// level's criteria are all skipped or unimplemented, it is acceptable, but
// weird.
local levelPassed(criteria) =
  local results = std.map(function(criterion) criterion.result, criteria);

  misc.all(function(result) result != 'failed', std.prune(results));

local evaluateLevel(level, service) =
  local criteria = std.map(function(criterion) evaluateCriterion(criterion, service), level.criteria);

  {
    name: level.name,
    passed: levelPassed(criteria),
    criteria: criteria,
  };

local evaluate(service, levels) =
  std.map(function(level) evaluateLevel(level, service), levels);

{
  evaluate: evaluate,
}
