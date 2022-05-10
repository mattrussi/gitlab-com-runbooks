local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local kubeLabelSelectors = metricsCatalog.kubeLabelSelectors;

metricsCatalog.serviceDefinition({
  type: 'consul',
  tier: 'sv',
  monitoringThresholds: {
    apdexScore: 0.95,
    errorRatio: 0.95,
  },
  provisioning: {
    vms: true,
    kubernetes: true,
  },
  regional: true,
  kubeConfig: {
    labelSelectors: kubeLabelSelectors(
      hpaSelector=null,  // no hpas for consul
      ingressSelector=null,  // no ingress for consul
      deploymentSelector=null,  // no deployments for consul
    ),
  },
  kubeResources: {
    consul: {
      kind: 'Daemonset',
      containers: [
        'consul',
      ],
    },
  },
  serviceLevelIndicators: {
    raft_logs: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        Raft log entry include adding nodes, adding services, new keys and values, etc. Increases in this metric can indicate higher load on the Consul servers and carry the risk of stale data.
      |||,
      apdex: histogramApdex(
        // Time it takes a Raft leader to write a log to disk, in milliseconds
        histogram='consul_raft_rpc_appendEntries',
        selector={ type: 'consul' },
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),
      requestRate: rateMetric(
        counter='consul_raft_leader_dispatchLog_count',
        selector={ type: 'consul' }
      ),

      significantLabels: ['fqdn'],
    },
    raft_commits: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        A Raft log is committed when the leader saves the new logs to disk, and confirms that the most recently saved log matches the most recent log in the leader’s memory. An increase in commit time can indicate heightened load on the Consul servers, and might indicate that clients are accessing stale data.
      |||,
      apdex: histogramApdex(
        // Time it takes to commit a new entry to the Raft log on the leader, in milliseconds
        histogram='consul_raft_commitTime',
        selector={ type: 'consul' },
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),
      requestRate: rateMetric(
        counter='consul_raft_apply',
        selector={ type: 'consul' }
      ),
      significantLabels: ['fqdn'],
    },
    dns: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors the DNS API that makes it possible to retrieve network details for services and nodes
      |||,
      apdex: histogramApdex(
        // How long it takes for a node to process a DNS query, including the response, in milliseconds
        histogram='consul_dns_domain_query',
        selector={ type: 'consul' },
        satisfiedThreshold=0.05,
        toleratedThreshold=0.1
      ),
      requestRate: rateMetric(
        counter='consul_dns_domain_query_count',
        selector={ type: 'consul' }
      ),
      significantLabels: [],
      toolingLinks: [
        toolingLinks.kibana(title='Consul', index='consul', includeMatchersForPrometheusSelector=false),
      ],
    },
  },
})
