local serviceCatalog = import 'service-catalog/service_catalog.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics-catalog.libsonnet';

// Like Rails's #present? (nulls, false, and empty are not present), but
// allows nulls to either return `false` or `null`.
local isPresent(object, nullValue=false) =
  if object == null then
    nullValue
  else if std.isBoolean(object) then
    object
  else
    std.length(object) > 0;

local all(func, collection) =
  std.foldl(function(accumulator, item) accumulator && func(item), collection, true);

local any(func, collection) =
  std.foldl(function(accumulator, item) accumulator || func(item), collection, false);

local values(hash) = std.map(function(k) hash[k], std.objectFields(hash));

local metricsDashboardLink(serviceName) =
  'https://dashboards.gitlab.net/d/general-service/general-service-platform-metrics?var-type=%s' % serviceName;

local levels = [
  {
    name: 'Level 1',
    criteria: [
      {
        name: 'Exists in the service catalog',
        evidence: function(service)
          if isPresent(serviceCatalog.lookupService(service.type)) then
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
            values(service.serviceLevelIndicators)
          ),
      },
    ],
  },
  {
    name: 'Level 2',
    criteria: [
      {
        name: 'SLO monitoring: apdex',
        evidence: function(service)
          if any(function(sli) std.objectHas(sli, 'apdex'), values(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        name: 'SLO monitoring: error rate',
        evidence: function(service)
          if any(function(sli) std.objectHas(sli, 'errorRate'), values(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        name: 'SLO monitoring: request rate',
        evidence: function(service)
          if any(function(sli) std.objectHas(sli, 'requestRate'), values(service.serviceLevelIndicators)) then
            metricsDashboardLink(service.type)
          else
            false,
      },
      {
        // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/829
        name: 'Metrics on downstream service usage',
        evidence: function(service) null,
      },
    ],
  },
  {
    name: 'Level 3',
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
          local components = values(service.serviceLevelIndicators);
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
    ],
  },
  {
    // TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/834
    name: 'Level 4',
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

local evaluateCriterion(criterion, service) =
  local evidence = criterion.evidence(service);

  {
    name: criterion.name,
    passed: isPresent(evidence, nullValue=null),
    evidence: evidence,
  };

// A level passes if:
// 1. It doesn't have any failures.
// 2. It has at least one pass.
//
// Nulls count as passed for item 1 because they are not implemented
// yet, but item 2 only checks implemented criteria.
local levelPassed(criteria) =
  local softPass(passed) = if passed == 'null' then true else passed;
  local passedValues = std.map(function(criterion) criterion.passed, criteria);

  all(softPass, std.prune(passedValues)) && any(softPass, std.prune(passedValues));

local evaluateLevel(level, service) =
  local criteria = std.map(function(criterion) evaluateCriterion(criterion, service), level.criteria);

  {
    name: level.name,
    passed: levelPassed(criteria),
    criteria: criteria,
  };

local evaluate(service) =
  std.map(function(level) evaluateLevel(level, service), levels);

// TODO: https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/827
std.foldl(function(accumulator, service) accumulator { [service.type]: evaluate(service) },
          metricsCatalog.services,
          {})
