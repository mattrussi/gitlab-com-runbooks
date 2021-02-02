local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceCatalog = import 'service_catalog.json';
local link = grafana.link;

local serviceMap = {
  [x.name]: x
  for x in serviceCatalog.services
};

local safeMap(fn, v) = if std.isArray(v) then std.map(fn, v) else [];

{
  lookupService(name)::
    if std.objectHas(serviceMap, name) then serviceMap[name],
  getLoggingLinks(name)::
    safeMap(function(log) link.dashboards('Logs: ' + log.name + ' (servcat)', '', type='link', keepTime=false, targetBlank=true, url=log.permalink), serviceMap[name].technical.logging),
  getServiceLinks(name)::
    self.getLoggingLinks(name),

  getTeams()::
    serviceCatalog.teams,

  getTeam(teamName)::
    local team = std.filter(function(team) team.name == teamName, self.getTeams());
    assert std.length(team) == 1;
    team[0],

  findServices(filterFunc)::
    std.filter(filterFunc, serviceCatalog.services),
}
