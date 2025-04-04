local serviceCatalog = import 'service-catalog/service-catalog.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local miscUtils = import 'utils/misc.libsonnet';

local metricsDashboardLink(serviceName) =
  'https://dashboards.gitlab.net/d/general-service/general-service-platform-metrics?var-type=%s' % serviceName;

local diagramDashboardLink = 'https://dashboards.gitlab.net/d/%(uuid)s' % {
  uuid: toolingLinks.grafanaUid('diagrams/main.dashboard.jsonnet'),
};

local levels = [
  {
    name: 'Level 1',
    number: 1,
    criteria: [
      {
        name: 'Exists in the service catalog',
        evidence: function(service)
          if miscUtils.isPresent(serviceCatalog.lookupService(service.type)) then
            'https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.yml'
          else
            false,
      },
      {
        name: 'Structured logs available in Kibana',
        evidence: function(service)
          std.flatMap(
            function(component) std.filter(function(link) link.tool == 'kibana' && link.type == 'log',
                                           component.renderToolingLinks()),
            std.objectValues(service.serviceLevelIndicators)
          ),
      },
      {
        name: 'Service exists in the dependency graph',
        evidence: function(service)
          local serviceGraph = serviceCatalog.serviceGraph;
          if std.length(serviceGraph[service.type].inward) > 0 || std.length(serviceGraph[service.type].outward) > 0 then
            [diagramDashboardLink]
          else
            false,
      },
    ],
  },
  {
    name: 'Level 2',
    number: 2,
    criteria: [
      {
        name: 'SLO monitoring: apdex',
        evidence: function(service)
          if miscUtils.any(function(sli) std.objectHas(sli, 'apdex'), std.objectValues(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        name: 'SLO monitoring: error rate',
        evidence: function(service)
          if miscUtils.any(function(sli) std.objectHas(sli, 'errorRate'), std.objectValues(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        name: 'SLO monitoring: request rate',
        evidence: function(service)
          if miscUtils.any(function(sli) std.objectHas(sli, 'requestRate'), std.objectValues(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
    ],
  },
  {
    name: 'Level 3',
    number: 3,
    criteria: [
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/830
        name: 'Service health dashboards',
        evidence: function(service) null,
      },
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/831
        name: 'SLA calculations driven from SLO metrics',
        evidence: function(service) null,
      },
      {
        name: 'Apdex built from multiple sources',
        evidence: function(service)
          local components = std.objectValues(service.serviceLevelIndicators);
          local apdexComponents = std.filter(function(sli) std.objectHas(sli, 'apdex'), components);

          // If the service only has one component, and that has apdex,
          // then this is also fine.
          if std.length(apdexComponents) > 1 || (std.length(components) == 1 && std.length(apdexComponents) == 1) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/832
        name: 'Logging includes metadata for measuring scalability',
        evidence: function(service) null,
      },
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/833
        name: 'Developer guides exist in developer documentation',
        evidence: function(service) null,
      },
      {
        name: 'SRE guides exist in runbooks',
        evidence: function(service)
          // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/857
          'https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/%s' % service.type,
      },
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/829
        name: 'Metrics on downstream service usage',
        evidence: function(service) null,
      },
    ],
  },
  {
    // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/834
    name: 'Level 4',
    number: 4,
    criteria: [
      {
        name: 'Prepared Kibana dashboards',
        evidence: function(service) null,
      },
      {
        name: 'Dashboards linked from metrics catalogs',
        evidence: function(service) null,
      },
      {
        name: 'Automatic alert routing',
        evidence: function(service) null,
      },
    ],
  },
  {
    // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/835
    name: 'Level 5',
    number: 5,
    criteria: [
      {
        name: 'Long-term forecasting utilization and usage',
        evidence: function(service) null,
      },
      {
        name: '70% of requests covered by at least one SLI',
        evidence: function(service) null,
      },
      {
        name: 'Automatic alert routing',
        evidence: function(service) null,
      },
    ],
  },
];

local criteriaList =
  std.flatMap(
    function(level) std.map(
      function(criteria) { name: criteria.name, level: level.name },
      level.criteria
    ),
    levels
  );

local criteriaNames = std.map(function(criteria) criteria.name, criteriaList);
assert std.length(criteriaNames) == std.length(std.uniq(criteriaNames)) :
       'Duplicated criterias: %s' % std.join(', ', miscUtils.arrayDiff(criteriaNames, std.uniq(criteriaNames)));

local getCriteria(criteriaName) =
  local criteria = std.filter(function(c) c.name == criteriaName, criteriaList);
  assert std.length(criteria) == 1 :
         'Criteria not found %s' % criteriaName;
  criteria[0];

local skip(skipHash) =
  assert std.type(skipHash) == 'object' :
         'Maturity skip list must be a hash of criteria names and reasons';
  std.foldl(
    function(memo, key)
      assert std.type(skipHash[key]) != 'null' :
             'Maturity skip reason must be a string';
      memo {
        [getCriteria(key).name]: skipHash[key],
      },
    std.objectFields(skipHash),
    {}
  );

{
  getLevels():: levels,
  skip: skip,
}
