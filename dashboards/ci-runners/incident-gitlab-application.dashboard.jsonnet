local dashboardIncident = import 'stage-groups/verify-runner/dashboard_incident.libsonnet';

dashboardIncident.incidentDashboard(
  'gitlab-application',
  'gl-app',
  description=|||
    Here we will leave some useful notes for the incidents caused by autoscaling GitLab application stack problems.

    It's also a good place to link to rubooks (if any are available for this
    context) or any useful documentation.

    Metrics to add:
    - Workhorse long pooling stats Workhorse queueing (+ queueing limits and errors) stats,
    - Sidekiq queues summary (for pipeline.* queues),
    - API nodes load summary,
    - Runner API requests summary (partitioned by the endpoint in separate panels)
  |||,
)
.addUnderConstructionNote()
