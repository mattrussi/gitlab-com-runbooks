local combined = (import './combined.libsonnet').combined;
local histogramApdex = (import './histogram_apdex.libsonnet').histogramApdex;
local test = import 'test.libsonnet';

test.suite({
  testApdexQuerySingleHistogram: {
    actual: combined([
      histogramApdex(histogram='test_seconds_bucket', selector={}, satisfiedThreshold=1),
      histogramApdex(histogram='other_test_seconds_bucket', selector={}, satisfiedThreshold=2),
    ]).apdexQuery(aggregationLabels=['type'], selector={ env: 'gprd' }, rangeInterval='5m'),
    expect: |||
      sum by (type) (
        label_replace(rate(test_seconds_bucket{env="gprd",le="1"}[5m]), "_c", "0", "", "")
        or
        label_replace(rate(other_test_seconds_bucket{env="gprd",le="2"}[5m]), "_c", "1", "", "")
      )
      /
      (
        sum by (type) (
          label_replace(rate(test_seconds_bucket{env="gprd",le="+Inf"}[5m]), "_c", "0", "", "")
          or
          label_replace(rate(other_test_seconds_bucket{env="gprd",le="+Inf"}[5m]), "_c", "1", "", "")
        ) > 0
      )
    |||,
  },

  testApdexQueryDoubleHistogram: {
    actual: combined([
      histogramApdex(histogram='test_seconds_bucket', selector={}, satisfiedThreshold=1, toleratedThreshold=10),
      histogramApdex(histogram='other_test_seconds_bucket', selector={}, satisfiedThreshold=2, toleratedThreshold=20),
    ]).apdexQuery(aggregationLabels=['type'], selector={ env: 'gprd' }, rangeInterval='5m'),
    expect: |||
      sum by (type) (
        label_replace((
          sum by (type) (
            rate(test_seconds_bucket{env="gprd",le="1"}[5m])
          )
          +
          sum by (type) (
            rate(test_seconds_bucket{env="gprd",le="10"}[5m])
          )
        )
        /
        2
        , "_c", "0", "", "")
        or
        label_replace((
          sum by (type) (
            rate(other_test_seconds_bucket{env="gprd",le="2"}[5m])
          )
          +
          sum by (type) (
            rate(other_test_seconds_bucket{env="gprd",le="20"}[5m])
          )
        )
        /
        2
        , "_c", "1", "", "")
      )
      /
      (
        sum by (type) (
          label_replace(sum by (type) (
            rate(test_seconds_bucket{env="gprd",le="+Inf"}[5m])
          )
          , "_c", "0", "", "")
          or
          label_replace(sum by (type) (
            rate(other_test_seconds_bucket{env="gprd",le="+Inf"}[5m])
          )
          , "_c", "1", "", "")
        ) > 0
      )
    |||,
  },
})
