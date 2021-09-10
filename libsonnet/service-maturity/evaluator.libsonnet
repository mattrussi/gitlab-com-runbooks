local misc = import 'utils/misc.libsonnet';

local skippedCrition(criterion, service) =
  if std.objectHas(service, 'skippedMaturityCriteria') then
    local names = std.map(function(c) c.name, service.skippedMaturityCriteria);
    std.member(names, criterion.name)
  else
    false;

local evaluateCriterion(criterion, service) =
  if skippedCrition(criterion, service) then
    {
      name: criterion.name,
      result: 'skipped',
      evidence: null,
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
  local levels = std.filter(
    function(level) level.passed,
    evaluate(service, levelDefinitions),
  );
  if std.length(levels) == 0 then
    'Level 0'
  else
    levels[std.length(levels) - 1].name;

{
  evaluate: evaluate,
  maxLevel: maxLevel,
}
