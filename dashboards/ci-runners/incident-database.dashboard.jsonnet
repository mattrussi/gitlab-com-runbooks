local dashboardIncident = import 'stage-groups/verify-runner/dashboard_incident.libsonnet';

dashboardIncident.incidentDashboard(
  'database',
  description=|||
    Here we will leave some useful notes for the incidents caused by database problems.

    It's also a good place to link to rubooks (if any are available for this
    context) or any useful documentation.

    Metrics to add:
    - patroni apdex,
    - dead tuples percentage,
    - dead tuples number,
    - slow queries summary
  |||,
)
.addUnderConstructionNote()
