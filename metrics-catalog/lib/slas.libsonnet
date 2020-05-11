local serviceCatalog = import 'service_catalog.libsonnet';

local keyServices = serviceCatalog.findServices(function(service)
  std.objectHas(service.business.SLA, 'overall_sla_weighting') && service.business.SLA.overall_sla_weighting > 0);

local keyServiceRegExp = std.join('|', std.map(function(service) service.name, keyServices));

local keyServiceWeights = std.foldl(
  function(memo, item) memo {
    [item.name]: item.business.SLA.overall_sla_weighting,
  }, keyServices, {}
);

local getWeightedQuery(template, formatVars={}) =
  local items = [
    template % (formatVars {
                  type: type,
                  weight: keyServiceWeights[type],
                })
    for type in std.objectFields(keyServiceWeights)
  ];

  std.join('\n  or\n  ', items);

{
  internal: {
    getRecordingRules():: [{
      // Monitoring v2 SLA
      // This SLA is recorded from internal metrics and intended to internal consumption.
      // The value is calculated as the percentage of time that a set of key services are within the
      // internal monitoring SLOs. Both the apdex and error rate SLOs need to be within their target
      // for the service to be considered to be meeting it's SLO.

      // A weighted average is then calculated across the key services using the
      // `overall_sla_weighting` weight from the service catalog.
      record: 'sla:gitlab:ratio',
      labels: {
        sla_type: 'internal.v2',
      },
      expr: |||
        sum by (environment, env, stage) (
          %(scoreQuery)s
        )
        /
        sum by (environment, env, stage) (
          %(weightQuery)s
        )
      ||| % {
        scoreQuery: getWeightedQuery('min without(slo) (avg_over_time(slo_observation_status{type="%(type)s", monitor="global"}[5m])) * %(weight)d'),
        weightQuery: getWeightedQuery('max without(slo) (clamp_max(clamp_min(slo_observation_status{type="%(type)s", monitor="global"}, 1), 1)) * %(weight)d'),
      },
    }],

    // NB: this query takes into account values recorded in Prometheus prior to
    // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
    // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
    getAggregatedVisualizationQuery(environment, interval)::
      |||
        avg(
          clamp_max(
            avg_over_time(
              sla:gitlab:ratio{env=~"ops|%(environment)s", environment="%(environment)s", stage="main", monitor=~"global|", sla_type=~"|monitoring.v2"}[%(interval)s]
            ),
            1
          )
        )
      ||| % {
        environment: environment,
        interval: interval,
      },

    getVisualizationQueryPerService(environment, interval)::
      |||
        avg by (type) (
          clamp_max(
            avg_over_time(slo_observation_status{env=~"ops|%(environment)s", environment="%(environment)s", stage="main", type=~"%(keyServiceRegExp)s"}[%(interval)s]),
            1
          )
        )
      ||| % {
        environment: environment,
        interval: interval,
        keyServiceRegExp: keyServiceRegExp,
      },
  },

  external: {
    getRecordingRules():: [{
      // External v1 SLA
      // This SLA is recorded from external blackbox results and intended to external consumption.
      // A series of endpoint URLs are tested via Pindom, and average availability for these endpoints
      // is then calculated over various time scales.
      // These values are then aggregated using a weighted average calculated across the key services
      // using the `overall_sla_weighting` weight from the service catalog.
      record: 'sla:gitlab:ratio',
      labels: {
        sla_type: 'external.v1',
      },
      expr: |||
        sum by (environment, env) (
          %(scoreQuery)s
        )
        /
        sum by (environment, env) (
          %(weightQuery)s
        )
      ||| % {
        scoreQuery: getWeightedQuery('avg by (environment, env, type) (gitlab_service_external_availability:ratio_5m{type="%(type)s", monitor!="global"}) * %(weight)d'),
        weightQuery: getWeightedQuery('max by (environment, env, type) (clamp_max(clamp_min(gitlab_service_external_availability:ratio_5m{type="%(type)s", monitor!="global"}, 1), 1)) * %(weight)d'),
      },
    }],


    // Note: once the recording rule has sufficient data, we should switch to that. For the moment,
    // rely on the underlying data
    getAggregatedVisualizationQuery(environment, interval)::
      local formatVars = { environment: environment, interval: interval };
      |||
        sum (
          %(scoreQuery)s
        )
        /
        sum (
          %(weightQuery)s
        )
      ||| % {
        scoreQuery: getWeightedQuery('avg by (type) (avg_over_time(gitlab_service_external_availability:ratio_5m{env="%(environment)s", type="%(type)s", monitor!="global"}[%(interval)s]) * %(weight)d)', formatVars),
        weightQuery: getWeightedQuery('max by (type) (clamp_max(clamp_min(avg_over_time(gitlab_service_external_availability:ratio_5m{env="%(environment)s", type="%(type)s", monitor!="global"}[%(interval)s]), 1), 1)) * %(weight)d', formatVars),
      },

  },
}
