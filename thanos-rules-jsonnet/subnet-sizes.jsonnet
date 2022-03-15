local subnetSizes = {
  'subnet-name': 12,
};

local subnetSizeRules = [
  {
    record: 'gitlab:gcp_subnet_max_ips',
    labels: {
      subnet: subnetName,
      env: 'gprd',
      environment: 'gprd',
    },
    expr: subnetSizes[subnetName],
  }
  for subnetName in std.objectFields(subnetSizes)
];

local subnetClusterMapping = {
  'gprd-gke-something': 'subnet-name',
};

local subnetClusterMappingRules = [
  {
    record: 'gitlab:cluster:subnet:mapping',
    labels: {
      subnet: subnetClusterMapping[clusterName],
      cluster: clusterName,
      env: 'gprd',
      environment: 'gprd',
    },
    expr: 1,
  }
  for clusterName in std.objectFields(subnetClusterMapping)
];

{
  'subnet-sizes.yml': std.manifestYamlDoc({
    groups: [
      {
        name: 'GCP Subnet size',
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: subnetSizeRules,
      },
      {
        name: 'Subnet Cluster mapping',
        interval: '1m',
        partial_response_strategy: 'warn',
        rules: subnetClusterMappingRules,
      },
    ],
  }),
}
