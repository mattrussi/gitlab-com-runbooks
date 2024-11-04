local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local rateMetric = metricsCatalog.rateMetric;
local cloudflareWorkerArchetype = import'service-archetypes/cloudflare-worker.libsonnet';

metricsCatalog.serviceDefinition(
  cloudflareWorkerArchetype(
    'http-router',
    team='tenant_scale',
    severity='s3',
    // Temporarily disable to avoid alerting for now.
    userImpacting=false,
  )
)
