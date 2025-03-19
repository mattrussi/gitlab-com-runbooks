/* TODO: having some sort of criticality label on sidekiq jobs would allow us to
   define different criticality labels for each worker. For now we need to use
   a fixed value, which also needs to be a lower-common-denominator */
local fixedApdexThreshold = 0.90;
local fixedErrorRateThreshold = 0.10;

local customThresholdsPerWorker = {
  'Ai::RepositoryXray::ScanDependenciesWorker': {
    errorRate: 0.001,
  },
};

local apdexThreshold = function(worker=null) fixedApdexThreshold;

local errorRateThreshold = function(worker=null)
  local thresholds = std.get(customThresholdsPerWorker, std.toString(worker), {});
  std.get(thresholds, 'errorRate', fixedErrorRateThreshold);

{
  apdexThreshold: apdexThreshold,
  errorRateThreshold: errorRateThreshold,
}
