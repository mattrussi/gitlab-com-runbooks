local serviceCatalog = (import 'gitlab-metrics-config.libsonnet').serviceCatalog;
local allServices = (import 'gitlab-metrics-config.libsonnet').monitoredServices;
local miscUtils = import 'utils/misc.libsonnet';

local serviceMap = {
  [x.name]: x
  for x in serviceCatalog.services
};

local teamDefaults = {
  issue_tracker: null,
  send_slo_alerts_to_team_slack_channel: false,
};

local buildServiceGraph(services) =
  std.foldl(
    function(graph, service)
      local dependencies =
        if std.objectHas(service, 'serviceDependencies') then
          miscUtils.arrayDiff(std.objectFields(service.serviceDependencies), [service.type])
        else
          [];
      if std.length(dependencies) > 0 then
        graph + {
          [dependency]: {
            inward: std.uniq([service.type] + graph[dependency].inward),
            outward: graph[dependency].outward,
          }
          for dependency in dependencies
        } + {
          [service.type]: {
            inward: graph[service.type].inward,
            outward: std.uniq(dependencies + graph[service.type].outward),
          },
        }
      else
        graph,
    services,
    std.foldl(
      function(graph, service) graph { [service.type]: { inward: [], outward: [] } },
      services,
      {}
    )
  );

{
  lookupService(name)::
    if std.objectHas(serviceMap, name) then serviceMap[name],

  buildServiceGraph: buildServiceGraph,
  serviceGraph:: buildServiceGraph(allServices),

  getTeams()::
    serviceCatalog.teams,

  getTeam(teamName)::
    local team = std.filter(function(team) team.name == teamName, self.getTeams());
    assert std.length(team) == 1;
    teamDefaults + team[0],

  findServices(filterFunc)::
    std.filter(filterFunc, serviceCatalog.services),

  findKeyBusinessServices(includeZeroScore=false)::
    std.filter(
      function(service)
        std.objectHas(service, 'business') &&
        std.objectHas(service.business.SLA, 'overall_sla_weighting') &&
        (if includeZeroScore then service.business.SLA.overall_sla_weighting >= 0 else service.business.SLA.overall_sla_weighting > 0),
      serviceCatalog.services
    ),
}
