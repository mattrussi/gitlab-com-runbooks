{
  type: 'registry',
  tier: 'sv',
  slos: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  components: {
    // The registry only has a single component, the docker/distribution server
    server: {
      // Satisfied -> 1 seconds
      apdexSatisfiedSeries: 'registry_http_request_duration_seconds_bucket{type="registry", le="1"}',

      // Tolerated -> 2.5 seconds
      apdexToleratedSeries: 'registry_http_request_duration_seconds_bucket{type="registry", le="2.5"}',

      apdexTotalSeries: 'registry_http_request_duration_seconds_count{type="registry"}',

      requestRateSeries: 'registry_http_requests_total{type="registry"}',

      errorRateSeries: 'registry_http_requests_total{type="registry", code=~"5.."}',
    },
  },
}
