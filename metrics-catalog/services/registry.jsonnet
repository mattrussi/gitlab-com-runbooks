local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local haproxyComponents = import './lib/haproxy_components.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;
local registryHelpers = import 'servicemetrics/helpers/registry-custom-route-slis.libsonnet';

local customRouteSLIs = [
  {
    name: 'server_route_manifest_reads',
    description: |||
      All read-requests (HEAD or GET) for the manifest endpoints on
      the registry.
      Fetch the manifest identified by name and reference where reference can be
      a tag or digest. A HEAD request can also be issued to this endpoint to
      obtain resource information without receiving all data.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.999,
    },
    satisfiedThreshold: 0.25,
    toleratedThreshold: 0.5,
    route: '/v2/{name}/manifests/{reference}',
    methods: ['get', 'head'],
  },
  {
    name: 'server_route_manifest_writes',
    description: |||
      All write-requests (put, delete) for the manifest endpoints on
      the registry.

      Put the manifest identified by name and reference where reference can be
      a tag or digest.

      Delete the manifest identified by name and reference. Note that a manifest
      can only be deleted by digest.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.999,
    },
    satisfiedThreshold: 1,
    toleratedThreshold: 2.5,
    route: '/v2/{name}/manifests/{reference}',
    // POST and PATCH are currently not part of the spec, but to avoid ignoring
    // them if they were introduced, we include them here.
    methods: ['put', 'delete', 'post', 'patch'],
  },
  {
    name: 'server_route_blob_upload_uuid_writes',
    description: |||
      Write requests (PUT or PATCH) for the registry blob upload endpoints.

      PUT is used to complete the upload specified by uuid, optionally appending
      the body as the final chunk.

      PATCH is used to upload a chunk of data for the specified upload.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.97,
    },
    satisfiedThreshold: 25,
    toleratedThreshold: 60,
    route: '/v2/{name}/blobs/uploads/{uuid}',
    // POST is currently not part of the spec, but to avoid ignoring it if it was
    // introduced, we include it here.
    methods: ['put', 'patch', 'post'],
  },
  {
    name: 'server_route_blob_upload_uuid_deletes',
    description: |||
      Delete requests for the registry blob upload endpoints.

      Used to cancel outstanding upload processes, releasing associated
      resources.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.997,
    },
    satisfiedThreshold: 2.5,
    toleratedThreshold: 5,
    route: '/v2/{name}/blobs/uploads/{uuid}',
    methods: ['delete'],
  },
  {
    name: 'server_route_blob_upload_uuid_reads',
    description: |||
      Read requests (GET) for the registry blob upload endpoints.

      GET is used to retrieve the current status of a resumable upload.

      This is currently not used on GitLab.com.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.997,
    },
    satisfiedThreshold: 1,
    toleratedThreshold: 2.5,
    route: '/v2/{name}/blobs/uploads/{uuid}',
    // HEAD is currently not part of the spec, but to avoid ignoring it
    // if it was introduced, we include it here.
    methods: ['get', 'head'],
    trafficCessationAlertConfig: false,
  },
];

local defaultRegistrySLIProperties = {
  userImpacting: true,
  featureCategory: 'container_registry',
};

local registryBaseSelector = {
  type: 'registry',
};

metricsCatalog.serviceDefinition({
  type: 'registry',
  tier: 'sv',

  tags: ['golang'],

  contractualThresholds: {
    apdexRatio: 0.9,
    errorRatio: 0.005,
  },
  otherThresholds: {
    // Deployment thresholds are optional, and when they are specified, they are
    // measured against the same multi-burn-rates as the monitoring indicators.
    // When a service is in violation, deployments may be blocked or may be rolled
    // back.
    deployment: {
      apdexScore: 0.9929,
      errorRatio: 0.9700,
    },

    mtbf: {
      apdexScore: 0.9995,
      errorRatio: 0.99995,
    },
  },
  monitoringThresholds: {
    apdexScore: 0.997,
    errorRatio: 0.9999,
  },
  serviceDependencies: {
    api: true,
    'redis-registry-cache': true,
  },
  provisioning: {
    kubernetes: true,
    vms: true,  // registry haproxy frontend still runs on vms
  },
  // Git service is spread across multiple regions, monitor it as such
  regional: true,
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      ingressSelector=null,  // no ingress for registry
      nodeSelector={ type: 'registry', stage: { oneOf: ['main', 'cny'] } },
    ),
  },
  kubeResources: {
    registry: {
      kind: 'Deployment',
      containers: [
        'registry',
      ],
    },
  },
  serviceLevelIndicators: {
    registry_cdn: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=true,
      loadBalancerName='gprd-registry-cdn',
      projectId='gitlab-production',
      featureCategory='container_registry',
    ),
    loadbalancer: haproxyComponents.haproxyHTTPLoadBalancer(
      userImpacting=true,
      featureCategory='container_registry',
      stageMappings={
        main: { backends: ['registry'], toolingLinks: [] },
        cny: { backends: ['canary_registry'], toolingLinks: [] },
      },
      selector=registryBaseSelector,
      regional=false
    ),

    registry_server: defaultRegistrySLIProperties {
      description: |||
        Aggregation of all registry requests.
      |||,

      apdex: registryHelpers.mainApdex(registryBaseSelector, customRouteSLIs),

      requestRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector
      ),

      errorRate: rateMetric(
        counter='registry_http_requests_total',
        selector=registryBaseSelector {
          code: { re: '5..' },
        }
      ),

      significantLabels: ['route', 'method'],

      toolingLinks: [
        toolingLinks.gkeDeployment('gitlab-registry', type='registry', containerName='registry'),
        toolingLinks.kibana(title='Registry', index='registry', type='registry', slowRequestSeconds=10),
        toolingLinks.continuousProfiler(service='gitlab-registry'),
      ],
    },

    database: {
      userImpacting: true,
      featureCategory: 'container_registry',
      description: |||
        Aggregation of all container registry database operations.
      |||,

      apdex: histogramApdex(
        histogram='registry_database_query_duration_seconds_bucket',
        selector={ type: 'registry' },
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='registry_database_queries_total',
        selector=registryBaseSelector
      ),

      significantLabels: ['name'],
    },

    garbagecollector: {
      severity: 's3',
      userImpacting: false,
      serviceAggregation: false,
      featureCategory: 'container_registry',
      description: |||
        Aggregation of all container registry online garbage collection operations.
      |||,

      apdex: histogramApdex(
        histogram='registry_gc_run_duration_seconds_bucket',
        selector={ type: 'registry' },
        satisfiedThreshold=0.5,
        toleratedThreshold=1
      ),

      requestRate: rateMetric(
        counter='registry_gc_runs_total',
        selector=registryBaseSelector
      ),

      errorRate: rateMetric(
        counter='registry_gc_runs_total',
        selector=registryBaseSelector {
          'error': 'true',
        }
      ),

      significantLabels: ['worker'],
      toolingLinks: [
        toolingLinks.kibana(
          title='Garbage Collector',
          index='registry_garbagecollection',
          type='registry',
          matches={ 'json.component': ['registry.gc.Agent', 'registry.gc.worker.ManifestWorker', 'registry.gc.worker.BlobWorker'] }
        ),
      ],
    },

    redis: {
      userImpacting: true,
      featureCategory: 'container_registry',
      description: |||
        Aggregation of all container registry Redis operations.
      |||,

      apdex: histogramApdex(
        histogram='registry_redis_single_commands_bucket',
        selector=registryBaseSelector,
        satisfiedThreshold=0.25,
        toleratedThreshold=0.5
      ),

      requestRate: rateMetric(
        counter='registry_redis_single_commands_count',
        selector=registryBaseSelector
      ),

      errorRate: rateMetric(
        counter='registry_redis_single_errors_count',
        selector=registryBaseSelector
      ),

      significantLabels: ['instance', 'command'],
    },
  } + registryHelpers.apdexPerRoute(registryBaseSelector, defaultRegistrySLIProperties, customRouteSLIs),
})

{
  /*
  *
  * Returns the unmodified config, this is used in tests to validate that all
  * methods for routes are defined
  */
  customApdexRouteConfig:: customRouteSLIs,
}
