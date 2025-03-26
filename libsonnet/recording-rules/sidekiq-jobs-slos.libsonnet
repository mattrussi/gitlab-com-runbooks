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

local workerErrorRate(worker) =
  'label_replace(vector(%(threshold)s), "worker", "%(worker)s", "", "")' % {
    worker: worker,
    threshold: customThresholdsPerWorker[worker].errorRate,
  };

local customErrorRateQuery(promQL) =
  local customThresholdsAsTimeSeries = [
    workerErrorRate(worker)
    for worker in std.objectFields(customThresholdsPerWorker)
  ];
  |||
    on(worker) group_left() (
        %(customThresholds)s
        or
        sum by(worker) (%(query)s) * 0 + %(fixedErrorRateThreshold)s
        unless on(worker)
        %(customThresholds)s
    )
  ||| % {
    query: promQL,
    customThresholds: std.join('\nor\n', customThresholdsAsTimeSeries),
    fixedErrorRateThreshold: fixedErrorRateThreshold,
  };

{
  apdexThreshold: apdexThreshold,
  errorRateThreshold: errorRateThreshold,
  customErrorRateQuery: customErrorRateQuery,
}
