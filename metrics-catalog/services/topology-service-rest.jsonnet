local runwayArchetype = import 'service-archetypes/runway-archetype.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition(
  runwayArchetype(
    type='topology-rest',
    team='tenant_scale',
    regional=true,
    // When using stackdriver_cloud_run_revision_run_googleapis_com_request_latencies_bucket as source metrics request latencies are put into specific
    // buckets this number is chosen to align with the closest desirable bucket see buckets here https://dashboards.gitlab.net/goto/vnxXtRZHg?orgId=1
    apdexSatisfiedThreshold='19.48717100000001',
    apdexScore=0.9995,
    errorRatio=0.9995,
    severity='s3'
  )
)
