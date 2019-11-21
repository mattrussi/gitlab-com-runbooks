{
  type: 'web',
  tier: 'sv',
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  components: {
    workhorse: {
      // Satisfied -> 1 second
      apdexSatisfiedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-web", le="1", route!="^/([^/]+/){1,}[^/]+/uploads\\\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      // Tolerated -> 10 seconds
      apdexToleratedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-web", le="10", route!="^/([^/]+/){1,}[^/]+/uploads\\\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      apdexTotalSeries: 'gitlab_workhorse_http_request_duration_seconds_count{job="gitlab-workhorse-web", route!="^/([^/]+/){1,}[^/]+/uploads\\\\z", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      requestRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-web"}',

      errorRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-web", code=~"^5.*"}',
    },

    unicorn: {
      // Satisfied -> 1 second
      apdexSatisfiedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="web", le="1"}',

      // Tolerated -> 10 seconds
      apdexToleratedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="web", le="10"}',

      apdexTotalSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="web"}',

      requestRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="web"}',

      errorRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="web", status=~"5.."}',
    },
  },
}
