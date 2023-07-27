local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;

local customRouteSLIs = [
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
    name: 'server_route_blob_digest_deletes',
    description: |||
      Delete requests for the blob digest endpoints on
      the registry.

      Used to delete blobs identified by name and digest.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.999,
    },
    satisfiedThreshold: 0.5,
    toleratedThreshold: 2.5,
    route: '/v2/{name}/blobs/{digest}',
    methods: ['delete'],
  },
  {
    name: 'server_route_blob_digest_reads',
    description: |||
      All read-requests (GET or HEAD) for the blob endpoints on
      the registry.

      GET is used to pull a layer gated by the name of repository
      and uniquely identified by the digest in the registry.

      HEAD is used to check the existence of a layer.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.95,
    },
    satisfiedThreshold: 10,
    toleratedThreshold: 60,
    route: '/v2/{name}/blobs/{digest}',
    methods: ['get', 'head'],
  },
  {
    name: 'server_route_blob_digest_writes',
    description: |||
      Write requests (PUT or PATCH or POST) for the registry blob digest endpoints.

      Currently not part of the spec.
    |||,
    monitoringThresholds+: {
      apdexScore: 0.997,
    },
    satisfiedThreshold: 2.5,
    toleratedThreshold: 25,
    route: '/v2/{name}/blobs/{digest}',
    // PATCH, POST, and PUT are currently not part of the spec, but to avoid ignoring them
    // if they were introduced, we include them here.
    methods: ['patch', 'post', 'put'],
  },
];

local defaultRegistrySLIProperties = {
  userImpacting: true,
};

local registryBaseSelector = {};

local registryApdex(selector, satisfiedThreshold, toleratedThreshold=null) =
  histogramApdex(
    histogram='registry_http_request_duration_seconds_bucket',
    selector=registryBaseSelector + selector,
    satisfiedThreshold=satisfiedThreshold,
    toleratedThreshold=toleratedThreshold,
  );

local mainApdex(
  selector=registryBaseSelector
      ) =
  local customizedRoutes = std.set(std.map(function(routeConfig) routeConfig.route, customRouteSLIs));
  local withoutCustomizedRouteSelector = selector {
    route: { nre: std.join('|', customizedRoutes) },
  };

  registryApdex(withoutCustomizedRouteSelector, satisfiedThreshold=2.5, toleratedThreshold=25);

local sliFromConfig(config) =
  local selector = registryBaseSelector {
    route: { eq: config.route },
    method: { re: std.join('|', config.methods) },
  };
  local toleratedThreshold =
    if std.objectHas(config, 'toleratedThreshold') then
      config.toleratedThreshold
    else
      null;
  defaultRegistrySLIProperties + config {
    apdex: registryApdex(selector, config.satisfiedThreshold, toleratedThreshold),
    requestRate: rateMetric(
      counter='registry_http_request_duration_seconds_count',
      selector=selector
    ),
    significantLabels: ['method'],
  };

local customRouteApdexes =
  std.foldl(
    function(memo, sliConfig) memo { [sliConfig.name]: sliFromConfig(sliConfig) },
    customRouteSLIs,
    {}
  );

{
  /*
   * This returns the base selector for the registry
   * { type: 'registry' }
   * To be used as a promql selector.
   * This allows the same selector to be for other SLIs.
   */
  registryBaseSelector:: registryBaseSelector,

  /*
   * These properties are the properties that can be reused in all registry SLIs
   *
   */
  defaultRegistrySLIProperties:: defaultRegistrySLIProperties,

  /*
   * This apdex contains of the routes that do not have a customized apdex
   * When adding routes to the customApdexRouteConfig, they will get excluded
   * from this one.
   */
  mainApdex:: mainApdex,

  /*
   * This contains an apdex for all of the routes-method combinations that have
   * a custom configuration
   */
  apdexPerRoute:: customRouteApdexes,

  /*
  *
  * Returns the unmodified config, this is used in tests to validate that all
  * methods for routes are defined
  */
  customApdexRouteConfig:: customRouteSLIs,
}
