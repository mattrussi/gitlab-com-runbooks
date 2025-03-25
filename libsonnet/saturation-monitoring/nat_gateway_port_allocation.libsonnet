local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local resourceSaturationPoint = metricsCatalog.resourceSaturationPoint;

{
  nat_gateway_port_allocation: resourceSaturationPoint({
    title: 'Cloud NAT Gateway Port Allocation',
    severity: 's2',

    // Technically, this is horizontally scalable, but requires us to send out
    // adequate notice to our customers before scaling it up, eg
    // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37444 and
    // https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3991 for examples
    horizontallyScalable: false,

    staticLabels: {
      type: 'nat',
      tier: 'inf',
      stage: 'main',
    },
    appliesTo: ['nat'],
    description: |||
      Each NAT IP address on a Cloud NAT gateway offers 64,512 TCP source ports and 64,512 UDP source ports.

      When these are exhausted, processes may experience connection problems to external destinations. In the application these
      may manifest as SMTP connection drops or webhook delivery failures. In Kubernetes, nodes may fail while
      attempting to download images from external repositories.

      More details in the Cloud NAT documentation: https://cloud.google.com/nat/docs/ports-and-addresses
    |||,
    grafana_dashboard_uid: 'sat_nat_gw_port_allocation',
    resourceLabels: ['gateway_name', 'project_id'],
    burnRatePeriod: '5m',  // This needs to be high, since the StackDriver export only updates infrequently
    queryFormatConfig: {
      // From https://cloud.google.com/nat/docs/ports-and-addresses#ports
      // Each NAT IP address on a Cloud NAT gateway offers 64,512 TCP source ports
      max_ports_per_nat_ip: 64512,
      // Number of IP addresses assigned to the NAT gateway.
      // Keep in sync with terraform "nat" module.
      // We have no queriable source for this, so for now we must manually update this count
      // whenever we add IPs to the NAT gateway via Terraform:
      // * For gprd: Sum of number of IPs used in both `nat_ips_us_east1_block_1` and `nat_ips_us_east1_block_2`.
      //   In practice, `nat_ips_us_east1_block_1` is always 16 (2^4), so this value turns out to be:
      //   # of IPs in `nat_ips_us_east1_block_2` + 16
      //   https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gprd/network.tf
      // * For gstg: Just copy `count` from `nat_us_east1`.
      //   https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/main/environments/gstg/network.tf
      gprd_nat_ip_count: 94,
      gstg_nat_ip_count: 16,
    },
    query: |||
      sum without(nat_ip) (
        stackdriver_nat_gateway_router_googleapis_com_nat_allocated_ports{
          project_id="gitlab-production",
          %(selectorWithoutType)s
        }
      )
      /
      ( %(max_ports_per_nat_ip)d * %(gprd_nat_ip_count)d )
      or
      sum without(nat_ip) (
        stackdriver_nat_gateway_router_googleapis_com_nat_allocated_ports{
          project_id="gitlab-staging-1",
          %(selectorWithoutType)s
        }
      )
      /
      ( %(max_ports_per_nat_ip)d * %(gstg_nat_ip_count)d )
    |||,
    slos: {
      soft: 0.80,
      hard: 0.90,
    },
  }),
}
