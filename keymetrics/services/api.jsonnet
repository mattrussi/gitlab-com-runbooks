{
  type: 'api',
  tier: 'sv',
  slos: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  components: {
    workhorse: {
      // Satisfied -> 1 second
      apdexSatisfiedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-api", type="api", le="1", route!="^/api/v4/jobs/request\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      // Tolerated -> 10 seconds
      apdexToleratedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-api", type="api", le="10", route!="^/api/v4/jobs/request\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      apdexTotalSeries: 'gitlab_workhorse_http_request_duration_seconds_count{job="gitlab-workhorse-api", type="api", route!="^/api/v4/jobs/request\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      requestRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-api", type="api"}',

      errorRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-api", type="api", code=~"^5.*"}',
    },

    unicorn: {
      // Satisfied -> 1 second
      apdexSatisfiedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="api", le="1"}',

      // Tolerated -> 10 seconds
      apdexToleratedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="api", le="10"}',

      apdexTotalSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="api"}',

      requestRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="api"}',

      errorRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="api", status=~"5.."}',
    },
  },
}
