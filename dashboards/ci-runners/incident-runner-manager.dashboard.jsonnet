local dashboardIncident = import 'stage-groups/verify-runner/dashboard_incident.libsonnet';

dashboardIncident.incidentDashboard(
  'runner-manager',
  description=|||
    Here we will leave some useful notes for the incidents caused by Runner Manager problems.

    It's also a good place to link to rubooks (if any are available for this
    context) or any useful documentation.

    Metrics to add:
    - runner instance resources utilization (for different resources that we track)
  |||,
)
.addUnderConstructionNote()
