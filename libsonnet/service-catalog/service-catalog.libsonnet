local serviceCatalog = (import 'gitlab-metrics-config.libsonnet').serviceCatalog;

local serviceMap = {
  [x.name]: x
  for x in serviceCatalog.services
};

local teamDefaults = {
  issue_tracker: null,
  send_slo_alerts_to_team_slack_channel: false,
};


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
