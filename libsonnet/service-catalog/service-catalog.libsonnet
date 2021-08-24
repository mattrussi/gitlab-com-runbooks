// service_catalog.json is stored in the `services` directory
// alongside service_catalog.yml
local serviceCatalog = import 'service_catalog.json';

local serviceMap = {
  [x.name]: x
  for x in serviceCatalog.services
};

local teamDefaults = {
  issue_tracker: null,
  send_slo_alerts_to_team_slack_channel: false,
};

local safeMap(fn, v) = if std.isArray(v) then std.map(fn, v) else [];

{
  lookupService(name)::
    if std.objectHas(serviceMap, name) then serviceMap[name],

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
