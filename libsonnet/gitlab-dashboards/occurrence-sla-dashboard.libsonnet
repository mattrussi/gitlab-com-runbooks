local availabilityPromql = import 'gitlab-availability/availability-promql.libsonnet';
local grafanaCalHeatmap = import 'grafana-cal-heatmap-panel/panel.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local strings = import 'utils/strings.libsonnet';

local milisecondsQuery(ratioQuery) =
  |||
    (
      1 - (
        %s
      )
    ) * $__range_ms
  ||| % [strings.indent(ratioQuery, 4)];
local budgetMinutesColor = {
  color: 'light-blue',
  value: null,
};

local clampRatio(ratioQuery) =
  |||
    clamp_max(
      clamp_min(
        %s,
        0
      ),
      1
    )
  ||| % [strings.indent(ratioQuery, 4)];

local slaRow(availability, services, selector) =
  local overallAvailabilitRatio = clampRatio(
    availability.availabilityRatio(
      aggregationLabels=[],
      selector=selector,
      services=services,
      range='$__range',
    )
  );
  local serviceName = if std.length(services) == 1 then services[0] else 'Overall';
  [
    basic.slaStats(
      title='%s availability' % [serviceName],
      query=overallAvailabilitRatio,
    ),
    basic.slaStats(
      title='',
      query=milisecondsQuery(overallAvailabilitRatio),
      legendFormat='',
      displayName='Budget Spent',
      decimals=1,
      unit='ms',
      colors=[budgetMinutesColor],
      colorMode='value',
    ),
    grafanaCalHeatmap.heatmapCalendarPanel(
      'Calendar',
      query=availability.availabilityRatio(
        aggregationLabels=[],
        selector=selector,
        services=services,
        range='1d',
      ),
      legendFormat='',
      datasource='$PROMETHEUS_DS',
      intervalFactor=1,
      threshold='0.9995'
    ),
    basic.slaTimeseries(
      title='%s SLA over time period' % [serviceName],
      description='Availability over time, higher is better.',
      yAxisLabel='SLA',
      query=clampRatio(availability.availabilityRatio(
        aggregationLabels=[],
        selector=selector,
        services=services,
        range='$__interval',
      )),
      legendFormat='%s SLA' % [serviceName],
      intervalFactor=1,
      legend_show=false
    ),
  ];

local dashboard(availability, keyServices, selector) =
  basic.dashboard(
    'Occurence SLAs',
    tags=['general', 'slas', 'service-levels'],
    includeStandardEnvironmentAnnotations=false,
    time_from='now-1M/M',
    time_to='now-1d/d',
  ).addPanels(
    layout.titleRowWithPanels(
      title='Overall GitLab availability',
      collapse=false,
      startRow=5,
      panels=layout.columnGrid(
        rowsOfPanels=[slaRow(availability, keyServices, selector)],
        columnWidths=[4, 4, 4, 12],
        rowHeight=5,
        startRow=10
      ),
    )
  ).addPanels(
    layout.titleRowWithPanels(
      title='GitLab Primary Service Availability',
      collapse=false,
      startRow=15,
      panels=layout.columnGrid(
        rowsOfPanels=[
          slaRow(availability, [service], selector)
          for service in keyServices
        ],
        columnWidths=[4, 4, 4, 12],
        rowHeight=5,
        startRow=15
      ),
    ),
  );

{
  dashboard(keyServices, aggregationSet, extraSelector={}):
    local availability = availabilityPromql.new(keyServices, aggregationSet);
    dashboard(availability, keyServices, extraSelector),
}
