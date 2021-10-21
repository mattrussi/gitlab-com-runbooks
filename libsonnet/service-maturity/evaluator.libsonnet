local misc = import 'utils/misc.libsonnet';

local checkSkippedCrition(criterion, service) =
  if std.objectHas(service, 'skippedMaturityCriteria') then
    assert std.type(service.skippedMaturityCriteria) == 'object' :
           'Maturity skip list must be a hash of criteria names and reasons';
    if std.objectHas(service.skippedMaturityCriteria, criterion.name) then
      service.skippedMaturityCriteria[criterion.name]
    else
      null
  else
    null;

local evaluateCriterion(criterion, service) =
  local skippedReason = checkSkippedCrition(criterion, service);
  if skippedReason != null then
    {
      name: criterion.name,
      result: 'skipped',
      evidence: skippedReason,
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
// level's criteria are all unimplemented, the level is considered to be
// failed. If a level's criteria are all skipped, the level is passed.
local levelPassed(criteria) =
  local results = std.map(function(criterion) criterion.result, criteria);

  misc.all(function(result) result != 'failed', std.prune(results)) &&
  misc.any(function(result) result != 'unimplemented', std.prune(results));

local evaluateLevel(level, service) =
  local criteria = std.map(function(criterion) evaluateCriterion(criterion, service), level.criteria);

  {
    name: level.name,
    passed: levelPassed(criteria),
    criteria: criteria,
  };

local evaluate = function(service, levels) std.map(function(level) evaluateLevel(level, service), levels);

local maxLevel(service, levelDefinitions) =
  std.foldl(
    function(acc, level)
      if level.passed && acc.passed then
        { passed: true, level: level.name }
      else
        { passed: false, level: acc.level },
    evaluate(service, levelDefinitions),
    { passed: true, level: 'Level 0' }
  ).level;

{
  evaluate: evaluate,
  maxLevel: maxLevel,
}
