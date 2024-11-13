# HostedRunnersServiceCiRunnerJobsApdexSLOViolationSingleShard

This alert triggers when the Apdex score for GitLab Hosted Runners drops below the predefined threshold, signaling potential performance degradation. The Apdex violation occurs when a runner fails to pick up jobs within the expected time, indicating a decline in user experience.

**Possible Causes**

• **Traffic spikes**: Unexpected traffic can lead to resource exhaustion (e.g., CPU, memory).
• **Database issues**: Slow queries, connection problems, or database performance degradation.
• **Recent deployments**: New code releases could introduce bugs or performance problems.
• **Network or server problems**: Performance impacted by underlying infrastructure issues.

**General Troubleshooting Steps**

1. **Identify slow requests via SLI metrics**
    • Review Service Level Indicators (SLIs) to identify metrics with elevated request times.
    • Examine logs and metrics around these slow requests to understand the performance degradation.
    • Check API request for `500` errors:
        ```
        sum(increase(gitlab_runner_api_request_statuses_total{status=~"5.."}[5m])) by (status, endpoint)
        ```
2. **Job Queue**
    • Pending job queue duration histogram percentiles may also point to a degradation, note that these are only for jobs that have been picked up by a runner.
3. **Review logs and metrics**
    • **Logs**: Search for errors, timeouts, or slow queries related to the affected services.
    • **Metrics**: Use Prometheus/Grafana to observe CPU, memory, and network utilization metrics for anomalies.
4. **Investigate recent deployments**
    • Identify if any recent code, configuration changes, or infrastructure updates have occurred.
    • Rollback or redeploy services if the issue is related to a faulty deployment.
5. **Examine traffic patterns and spikes**
    • Analyze traffic logs and monitoring dashboards for unusual spikes.
    • Assess whether traffic surges correlate with the Apdex violations and resource exhaustion.
