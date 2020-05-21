local aggregations = import './aggregations.libsonnet';
local selectors = import './selectors.libsonnet';

local chomp(str) = std.rstripChars(str, '\n');
local removeBlankLines(str) = std.strReplace(str, '\n\n', '\n');
local indent(str, spaces) =
  std.strReplace(removeBlankLines(chomp(str)), '\n', '\n' + std.repeat(' ', spaces));

local orJoin(queries) =
  std.join('\nor\n', queries);

local relabelWithIndex(query, index) =
  'label_replace(
      %(query)s,
      "_i", "%(index)d", "", ""
    )' % {
    query: indent(query, 2),
    index: index
  };

local sumWithoutIndexLabel(query) =
  'sum without(_i) (
    %s
  )' % indent(chomp(query), 2);

local generateRateQuery(c, selector, rangeInterval) =
  local rateQueries = std.mapWithIndex(function(index, e) relabelWithIndex(e.rateQuery(selector, rangeInterval), index), c.metrics);
  orJoin(rateQueries);

local generateIncreaseQuery(c, selector, rangeInterval) =
  local increaseQueries = std.mapWithIndex(function(index, e) relabelWithIndex(e.increaseQuery(selector, rangeInterval), index), c.metrics);
  orJoin(increaseQueries);

local generateApdexQuery(c, aggregationLabels, selector, rangeInterval) =
  local numeratorQueries = std.mapWithIndex(function(index, e) relabelWithIndex(e.apdexNumerator(aggregationLabels, selector, rangeInterval), index), c.metrics);
  local weightQueries = std.mapWithIndex(function(index, e) relabelWithIndex(e.apdexWeightQuery(aggregationLabels, selector, rangeInterval), index), c.metrics);
  local joinedNumerators = sumWithoutIndexLabel(orJoin(numeratorQueries));
  local joinedWeights = sumWithoutIndexLabel(orJoin(weightQueries));

  |||
    %(joinedNumerators)s
    /
    (
      %(joinedWeights)s > 0
    )
  ||| % {
    joinedNumerators: chomp(joinedNumerators),
    joinedWeights: indent(chomp(joinedWeights), 2),
  };

local generateApdexWeightQuery(c, aggregationLabels, selector, rangeInterval) =
  local apdexWeightQueries = std.map(function(i) i.apdexWeightQuery(aggregationLabels, selector, rangeInterval), c.metrics);
  sumWithoutIndexLabel(orJoin(apdexWeightQueries));

local generateApdexPercentileLatencyQuery(c, percentile, aggregationLabels, selector, rangeInterval) =
  local aggregationLabelsWithLe = selectors.join([aggregationLabels, 'le']);
  local apdexWeightQueries = std.map(function(i) i.aggregatedRateQuery(aggregationLabelsWithLe, selector, rangeInterval), c.metrics);
  local joined = orJoin(apdexWeightQueries);

  |||
    histogram_quantile(
      %(percentile)f,
      %(aggregatedRateQuery)s
    )
  ||| % {
    percentile: percentile,
    aggregatedRateQuery: indent(chomp(joined), 2),
  };

// "combined" allows two counter metrics to be added together
// to generate a new metric value
{
  combined(
    metrics
  ):: {
    metrics: metrics,

    // This creates a rate query of the form
    // rate(....{<selector>}[<rangeInterval>])
    rateQuery(selector, rangeInterval)::
      sumWithoutIndexLabel(generateRateQuery(self, selector, rangeInterval)),

    // This creates a increase query of the form
    // rate(....{<selector>}[<rangeInterval>])
    increaseQuery(selector, rangeInterval)::
      sumWithoutIndexLabel(generateIncreaseQuery(self, selector, rangeInterval)),

    // This creates an aggregated rate query of the form
    // sum by(<aggregationLabels>) (...)
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateRateQuery(self, selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),

    // This creates an aggregated increase query of the form
    // sum by(<aggregationLabels>) (...)
    aggregatedIncreaseQuery(aggregationLabels, selector, rangeInterval)::
      local query = generateIncreaseQuery(self, selector, rangeInterval);
      aggregations.aggregateOverQuery('sum', aggregationLabels, query),

    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexQuery(self, aggregationLabels, selector, rangeInterval),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexWeightQuery(self, aggregationLabels, selector, rangeInterval),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      generateApdexPercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

    firstMetric()::
      metrics[0],

    // Forward the below methods and fields to the first metric for
    // apdex scores, which is wrong but hopefully not catastrophic.
    describe()::
      self.firstMetric().describe(),

    toleratedThreshold:
      self.firstMetric().toleratedThreshold,

    satisfiedThreshold:
      self.firstMetric().satisfiedThreshold,

  },
}
