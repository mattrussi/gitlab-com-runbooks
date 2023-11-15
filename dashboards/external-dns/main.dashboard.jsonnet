local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local row = grafana.row;

local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';

serviceDashboard.overview('external-dns')
.addPanel(
  row.new(title='ExternalDNS Sync and Reconciliation', collapse=true)
  .addPanels(
    layout.grid([
      basic.timeseries(
        title='Reconcile Lag',
        description=|||
          Time since the last reconciliation with GCP Cloud DNS.
        |||,
        query='time() - external_dns_controller_last_reconcile_timestamp_seconds{environment="$environment"}',
        legendFormat='{{ cluster }} ({{ region }}))',
        format='s',
      ),
      basic.timeseries(
        title='Sync Lag',
        description=|||
          Time since the last sync from Kubernetes sources.
        |||,
        query='time() - external_dns_controller_last_sync_timestamp_seconds{environment="$environment"}',
        legendFormat='{{ cluster }} ({{ region }}))',
        format='s',
      ),
      basic.timeseries(
        title='Source Errors',
        description=|||
          Error rate while syncing from Kubernetes sources.
        |||,
        query='sum(rate(external_dns_source_errors_total{environment="$environment"}[$__interval])) by (region, cluster)',
        legendFormat='{{ cluster }} ({{ region }}))',
        format='short',
      ),
      basic.timeseries(
        title='Registry Errors',
        description=|||
          Error rate while reconciling with GCP Cloud DNS.
        |||,
        query='sum(rate(external_dns_registry_errors_total{environment="$environment"}[$__interval])) by (region, cluster)',
        legendFormat='{{ cluster }} ({{ region }}))',
        format='short',
      ),
    ], cols=2, rowHeight=10, startRow=1),
  ),
  gridPos={ x: 0, y: 300, w: 24, h: 1 },
)
.overviewTrailer()
