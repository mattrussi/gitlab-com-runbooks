local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'nat',
  tier: 'inf',
  serviceIsStageless: true,  // nat does not have a cny stage
  monitoringThresholds: {
    // TODO: define thresholds for the NAT service
  },
  serviceDependencies: {
    frontend: true,
  },
  provisioning: {
    kubernetes: false,
    vms: false,
  },
  local baseSelector = {
    metric_prefix: 'router.googleapis.com/nat',
    ip_protocol: '6',
    project_id: { oneOf: ['gitlab-staging-1', 'gitlab-production'] },
  },
  serviceLevelIndicators: {
    sent_tcp_packets: {
      userImpacting: true,
      featureCategory: 'not_owned',

      description: |||
        Monitors GCP Cloud NAT TCP packets sent.
        Request rate is measures in IP packets, sent by the Cloud NAT.
        Errors are dropped packets.

        High error rates could lead to network issues, including application errors, container fetch failures, etc.
      |||,

      requestRate: customRateQuery(
        query=|||
          sum by (environment) (
            avg_over_time(
              %(metric)s{%(selector)s}[%(burnRate)s]
            )
          )
        |||,
        metric='stackdriver_nat_gateway_router_googleapis_com_nat_sent_packets_count',
        selector=baseSelector
      ),

      // The error rate counts the number of dropped sent TCP packets by the Cloud NAT gateway
      errorRate: customRateQuery(
        query=|||
          sum by (environment) (
            avg_over_time(
              %(metric)s{%(selector)s}[%(burnRate)s]
            )
          )
        |||,
        metric='stackdriver_nat_gateway_router_googleapis_com_nat_dropped_sent_packets_count',
        selector=baseSelector
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'Cloud NAT Stackdriver Dropped Packet Logs',
          queryHash={
            'resource.type': 'nat_gateway',
            'jsonPayload.allocation_status': { ne: 'OK' },
          },
        ),
      ],
    },

    received_tcp_packets: {
      userImpacting: true,
      featureCategory: 'not_owned',

      description: |||
        Monitors GCP Cloud NAT TCP packets received.
        Request rate is measures in IP packets, received by the Cloud NAT.
        Errors are dropped packets.

        High error rates could lead to network issues, including application errors, container fetch failures, etc.
      |||,

      requestRate: customRateQuery(
        query=|||
          sum by (environment) (
            avg_over_time(
              %(metric)s{%(selector)s}[%(burnRate)s]
            )
          )
        |||,
        metric='stackdriver_nat_gateway_router_googleapis_com_nat_received_packets_count',
        selector=baseSelector
      ),

      // The error rate counts the number of dropped received TCP packets by the Cloud NAT gateway
      errorRate: customRateQuery(
        query=|||
          sum by (environment) (
            avg_over_time(
              %(metric)s{%(selector)s}[%(burnRate)s]
            )
          )
        |||,
        metric='stackdriver_nat_gateway_router_googleapis_com_nat_dropped_received_packets_count',
        selector=baseSelector
      ),

      significantLabels: [],

      toolingLinks: [
        toolingLinks.stackdriverLogs(
          'Cloud NAT Stackdriver Dropped Packet Logs',
          queryHash={
            'resource.type': 'nat_gateway',
            'jsonPayload.allocation_status': { ne: 'OK' },
          },
        ),
      ],
    },
  },
  skippedMaturityCriteria: {
    'Developer guides exist in developer documentation': 'NAT is an infrastructure component, developers do not interact with it',
    'Structured logs available in Kibana': 'NAT is managed by GCP, thus the logs are avaiable in Stackdriver.',
  },
})
