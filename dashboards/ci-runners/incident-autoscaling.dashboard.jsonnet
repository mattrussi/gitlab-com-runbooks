local dashboardIncident = import 'stage-groups/verify-runner/dashboard_incident.libsonnet';

dashboardIncident.incidentDashboard(
  'autoscaling',
  description=|||
    Here we will leave some useful notes for the incidents caused by autoscaling problems.

    It's also a good place to link to rubooks (if any are available for this
    context) or any useful documentation.

    Metrics to add:
    - docker machine VMs statuses,
    - docker machine operation,
    - docker machine operations timings,
  |||,
)
.addUnderConstructionNote()
