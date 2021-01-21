local generalServicesDashboard = import 'general-services-dashboard.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

local daysSinceLastFailure(serviceSelector, serviceName) =
  local title = 'Time since last failure (%(serviceName)s)' % {
    serviceName: serviceName,
  };
  basic.statPanel(
    title,
    title,
    'dark-blue',
    |||
      min(
        time() -
        gitlab_slo:last_violation_leading_timestamp{stage='$stage', env="$environment", environment="$environment", type=~"%(serviceSelector)s"}
      )
    ||| % {
      serviceSelector: serviceSelector,
    },
    '',
    unit='s',
  );

local mtbf(serviceSelector, serviceName) =
  basic.timeseries(
    title='Mean time between failures (%(serviceName)s)' % {
      serviceName: serviceName,
    },
    format='s',
    query=|||
      $__range_s / changes(
        max(
          gitlab_slo:last_violation_leading_timestamp{stage='$stage', env="$environment", environment="$environment", type=~"%(serviceSelector)s"}
        )[$__range:]
      )
    ||| % {
      serviceSelector: serviceSelector,
    }
  );

local serviceColumns(service='', title='') =
  local serviceSelector = (if service == '' then '.*' else service);
  [
    daysSinceLastFailure(serviceSelector, title),
    mtbf(serviceSelector, title),
  ];

local serviceRow(service) =
  serviceColumns(service.name, service.friendly_name);

local primaryServiceRows = std.map(serviceRow, generalServicesDashboard.sortedKeyServices);

basic.dashboard(
  'Mean Time Between Failure',
  time_from='now-7d',
  time_to='now/m',
  tags=['general'],
  includeStandardEnvironmentAnnotations=false,
).addTemplate(templates.stage)
.addPanel(
  grafana.row.new(title='Overall GitLab.com'),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
).addPanels(
  layout.columnGrid(
    [serviceColumns(title='GitLab.com')],
    [8, 16],
    rowHeight=10,
    startRow=1101,
  ),
).addPanel(
  grafana.row.new(title='Primary Services'),
  gridPos={
    x: 0,
    y: 2000,
    w: 24,
    h: 1,
  }
).addPanels(
  layout.columnGrid(primaryServiceRows, [8, 16], rowHeight=8, startRow=2101)
)
.trailer()
