{
  type: 'git',
  tier: 'sv',
  slos: {
    apdexRatio: 0.95,
    errorRatio: 0.005,
  },
  components: {
    workhorse: {
      // Satisfied -> 30 second
      apdexSatisfiedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-git", le="30", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      // Tolerated -> 60 seconds
      apdexToleratedSeries: 'gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-git", le="60", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      apdexTotalSeries: 'gitlab_workhorse_http_request_duration_seconds_count{job="gitlab-workhorse-git", route!="^/-/health$", route!="^/-/(readiness|liveness)$"}',

      requestRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-git"}',

      errorRateSeries: 'gitlab_workhorse_http_requests_total{job="gitlab-workhorse-git", code=~"^5.*"}',
    },

    unicorn: {
      // Satisfied -> 1 second
      apdexSatisfiedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="git", le="1"}',

      // Tolerated -> 10 seconds
      apdexToleratedSeries: 'http_request_duration_seconds_bucket{job="gitlab-rails", type="git", le="10"}',

      apdexTotalSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="git"}',

      requestRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="git"}',

      errorRateSeries: 'http_request_duration_seconds_count{job="gitlab-rails", type="git", status=~"5.."}',
    },

    gitlab_shell: {
      staticLabels: {
        tier: 'sv',
        stage: 'main',
      },

      requestRateQuery: |||
        sum by (environment) (haproxy_backend_current_session_rate{backend=~"ssh|altssh"})
      |||,
    },
  },
}
