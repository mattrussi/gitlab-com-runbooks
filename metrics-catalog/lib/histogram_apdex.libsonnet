local selectors = import './selectors.libsonnet';

local chomp(str) = std.rstripChars(str, '\n');
local removeBlankLines(str) = std.strReplace(str, '\n\n', '\n');

local indent(str, spaces) =
  std.strReplace(removeBlankLines(chomp(str)), '\n', '\n' + std.repeat(' ', spaces));

// A general apdex query is:
//
// 1. Some kind of satisfaction query (with a single threshold, a
//    double threshold, or even a combination of thresholds or-ed
//    together)
// 2. Divided by an optional denominator (when it's a double threshold
//    query; see
//    https://prometheus.io/docs/practices/histograms/#apdex-score)
// 3. Divided by some kind of weight score (either a single weight, or a
//    combination of weights or-ed together).
//
// The other functions here all use this to generate the final apdex
// query.

local generateApdexComponentRateQuery(histogramApdex, additionalSelectors, duration, leSelector='') =
  local selector = selectors.join([chomp(histogramApdex.selector), chomp(additionalSelectors), leSelector]);

  'rate(%(histogram)s{%(selector)s}[%(duration)s])' % {
    histogram: histogramApdex.histogram,
    selector: selector,
    duration: duration,
  };

local generateApdexComponentAggregationQuery(aggregationLabels, rateQuery) =
  |||
    sum by (%(aggregationLabels)s) (
      %(rateQuery)s
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    rateQuery: rateQuery,
  };

local generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, leSelector) =
  generateApdexComponentAggregationQuery(
    aggregationLabels,
    generateApdexComponentRateQuery(histogramApdex, additionalSelectors, duration, leSelector)
  );

// A single threshold apdex score only has a SATISFACTORY threshold, no TOLERABLE threshold
local generateSingleThresholdApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local satisfiedQuery = generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.satisfiedThreshold]);
  |||
    (
      %(satisfied)s
    )
  ||| % {
    satisfied: indent(satisfiedQuery, 2),
  };


// A double threshold apdex score only has both SATISFACTORY threshold and TOLERABLE thresholds
local generateDoubleThresholdApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local satisfiedQuery = generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.satisfiedThreshold]);
  local toleratedQuery = generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, 'le="%g"' % [histogramApdex.toleratedThreshold]);

  |||
    (
      %(satisfied)s
      +
      %(tolerated)s
    )
    /
    2
  ||| % {
    satisfied: indent(satisfiedQuery, 2),
    tolerated: indent(toleratedQuery, 2),
  };

local generateApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  if histogramApdex.toleratedThreshold == null then
    generateSingleThresholdApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration)
  else
    generateDoubleThresholdApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration);

local generateApdexScoreQuery(histogramApdex, aggregationLabels, additionalSelectors, duration) =
  local numeratorQuery = generateApdexNumeratorQuery(histogramApdex, aggregationLabels, additionalSelectors, duration);
  local weightQuery = generateApdexComponentQuery(histogramApdex, aggregationLabels, additionalSelectors, duration, 'le="+Inf"');

  |||
    %(numeratorQuery)s
    /
    (
      %(weightQuery)s > 0
    )
  ||| % {
    numeratorQuery: chomp(numeratorQuery),
    weightQuery: indent(chomp(weightQuery), 2),
  };


local generateAggregatedRateQuery(histogram, aggregationLabels, additionalSelectors, duration) =
  local rateQuery = generateApdexComponentRateQuery(histogram, additionalSelectors, duration);
  |||
    sum by (%(aggregationLabels)s) (
      %(rateQuery)s
    )
  ||| % {
    aggregationLabels: aggregationLabels,
    rateQuery: indent(chomp(rateQuery), 4),
  };

local generatePercentileLatencyQuery(histogram, percentile, aggregationLabels, additionalSelectors, duration) =
  local aggregationLabelsWithLe = selectors.join([aggregationLabels, 'le']);
  local aggregatedRateQuery = generateAggregatedRateQuery(histogram, aggregationLabelsWithLe, additionalSelectors, duration);

  |||
    histogram_quantile(
      %(percentile)f,
      %(aggregatedRateQuery)s
    )
  ||| % {
    percentile: percentile,
    aggregationLabelsWithLe: aggregationLabelsWithLe,
    aggregatedRateQuery: indent(chomp(aggregatedRateQuery), 2),
  };

{
  histogramApdex(
    histogram,
    selector='',
    satisfiedThreshold=null,
    toleratedThreshold=null
  ):: {
    histogram: histogram,
    selector: selector,
    satisfiedThreshold: satisfiedThreshold,
    toleratedThreshold: toleratedThreshold,

    apdexQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexScoreQuery(self, aggregationLabels, selector, rangeInterval),

    apdexNumerator(aggregationLabels, selector, rangeInterval)::
      generateApdexNumeratorQuery(self, aggregationLabels, selector, rangeInterval),

    apdexWeightQuery(aggregationLabels, selector, rangeInterval)::
      generateApdexComponentQuery(self, aggregationLabels, selector, rangeInterval, 'le="+Inf"'),

    percentileLatencyQuery(percentile, aggregationLabels, selector, rangeInterval)::
      generatePercentileLatencyQuery(self, percentile, aggregationLabels, selector, rangeInterval),

    // This is used to combine multiple apdex scores for a combined percentileLatencyQuery
    aggregatedRateQuery(aggregationLabels, selector, rangeInterval)::
      generateAggregatedRateQuery(self, aggregationLabels, selector, rangeInterval),

    describe()::
      local s = self;
      // TODO: don't assume the metric is in seconds!
      if s.toleratedThreshold == null then
        '%gs' % [s.satisfiedThreshold]
      else
        '%gs/%gs' % [s.satisfiedThreshold, s.toleratedThreshold],
  },
}
