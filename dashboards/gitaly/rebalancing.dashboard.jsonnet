local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'prom_query.libsonnet';
local serviceCatalog = import 'service_catalog.libsonnet';
local templates = import 'templates.libsonnet';
local dashboard = grafana.dashboard;
local graphPanel = grafana.graphPanel;
local link = grafana.link;

local balanceChart(
  title,
  description,
  format,
  legendFormat,
  query,
      ) =
  graphPanel.new(
    title,
    description=description,
    min=0,
    max=null,
    x_axis_mode='series',
    x_axis_values='current',
    lines=false,
    points=false,
    bars=true,
    format=format,
    legend_show=false,
    value_type='individual'
  )
  .addSeriesOverride({
    alias: '//',
    color: '#73BF69',
  })
  .addTarget(
    promQuery.target(
      query,
      instant=true,
      legendFormat=legendFormat,
    )
  ) + {
    tooltip: {
      shared: false,
      sort: 0,
      value_type: 'individual',
    },
  };

dashboard.new(
  'Rebalance Dashboard',
  schemaVersion=16,
  tags=['gitaly'],
  timezone='UTC',
  graphTooltip='shared_crosshair',
)
.addTemplate(templates.ds)
.addTemplate(templates.environment)
.addPanels(
  layout.grid([
    balanceChart(
      title='Balacing',
      description='Balancing Ranking. Equal is better.',
      format='short',
      query='\n        sort_desc(\n          max(rate(node_disk_read_bytes_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(rate(node_disk_read_bytes_total{environment="gprd", type="gitaly", device="sdb"}[6h]))\n\n          +\n\n          max(rate(node_disk_written_bytes_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(rate(node_disk_written_bytes_total{environment="gprd", type="gitaly", device="sdb"}[6h]))\n\n          +\n\n          max(rate(node_disk_reads_completed_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(max(rate(node_disk_reads_completed_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn))\n\n          +\n\n          max(rate(node_disk_writes_completed_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(max(rate(node_disk_writes_completed_total{environment="gprd", type="gitaly", device="sdb"}[6h])) by (fqdn))\n\n          +\n\n          sum(rate(grpc_client_started_total{environment="gprd", type="gitaly"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(rate(grpc_client_started_total{environment="gprd", type="gitaly"}[6h]))\n\n          +\n\n          sum(rate(grpc_client_started_total{environment="gprd", type="gitaly"}[6h])) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(rate(grpc_client_started_total{environment="gprd", type="gitaly"}[6h]))\n\n          +\n\n          avg(instance:node_filesystem_avail:ratio{environment="gprd", type="gitaly",device="/dev/sdb"}) by (fqdn)\n          / ignoring(fqdn) group_left\n          sum(avg(instance:node_filesystem_avail:ratio{environment="gprd", type="gitaly",device="/dev/sdb"}) by (fqdn))\n        )\n      ',
      legendFormat='{{ fqdn }}',
    ),
  ], cols=1, rowHeight=10, startRow=1)
)
.addPanels(
  layout.grid([
    balanceChart(
      title='Disk read bytes/second average',
      description='Average read throughput. Lower is better.',
      format='Bps',
      query='\n        sort_desc(max(rate(node_disk_read_bytes_total{environment="$environment", type="gitaly", device="sdb"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Disk write bytes/second average',
      description='Average write throughput. Lower is better.',
      format='Bps',
      query='\n        sort_desc(max(rate(node_disk_written_bytes_total{environment="$environment", type="gitaly", device="sdb"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Disk read operation/second average',
      description='Average write throughput. Lower is better.',
      format='ops',
      query='\n        sort_desc(max(rate(node_disk_reads_completed_total{environment="$environment", type="gitaly", device="sdb"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Disk write operation/second average',
      description='Average write throughput. Lower is better.',
      format='ops',
      query='\n        sort_desc(max(rate(node_disk_writes_completed_total{environment="$environment", type="gitaly", device="sdb"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Total Gitaly Request Time',
      description='Average seconds of Gitaly utilization per server per second. Lower is better.',
      format='s',
      query='\n        sort_desc(sum(rate(grpc_server_handling_seconds_sum{environment="$environment", type="gitaly"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Gitaly-Ruby Request Rate',
      description='Average number of Gitaly Ruby Requests/second. Lower is better.',
      format='ops',
      query='\n        sort_desc(sum(rate(grpc_client_started_total{environment="$environment", type="gitaly"}[$__range])) by (fqdn))\n      ',
      legendFormat='{{ fqdn }}',
    ),
    balanceChart(
      title='Disk Space Left',
      description='Disk free space available %. Lower is better.',
      format='percentunit',
      query='\n        sort_desc(\n          instance:node_filesystem_avail:ratio{environment="$environment", type="gitaly",device="/dev/sdb"}\n        )\n      ',
      legendFormat='{{ fqdn }}',
    ),

  ], cols=2, rowHeight=10, startRow=1000)
)
+ {
  links+: platformLinks.triage + serviceCatalog.getServiceLinks('gitaly') + platformLinks.services + [
    link.dashboards('ELK: Repository Utilization Report for Gitaly Rebalancing', '', type='link', keepTime=false, targetBlank=true, url='https://log.gitlab.net/goto/34aa59a70ff732505a88bf94d6e8beb1'),
  ],
}
