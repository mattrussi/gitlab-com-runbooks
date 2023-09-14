local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

local gaugeMetric = metricsCatalog.gaugeMetric;

metricsCatalog.serviceDefinition({
  type: 'packagecloud',
  tier: 'inf',

  tags: ['cloud-sql'],

  serviceIsStageless: true,

  provisioning: {
    kubernetes: true,
    vms: false,
  },

  regional: false,

  serviceDependencies: {
    'cloud-sql': true,
    kube: true,
    memorystore: true,
  },

  kubeConfig: {},
  kubeResources: {
    rainbows: {
      kind: 'Deployment',
      containers: [
        'packagecloud',
        'memorystore-tls',
      ],
    },
    resque: {
      kind: 'Deployment',
      containers: [
        'packagecloud',
        'memorystore-tls',
      ],
    },
    web: {
      kind: 'Deployment',
      containers: [
        'packagecloud',
        'memorystore-tls',
      ],
    },
    toolbox: {
      kind: 'Deployment',
      containers: [
        'packagecloud',
        'memorystore-tls',
      ],
    },
    'sql-proxy': {
      kind: 'Deployment',
      containers: [
        'sqlproxy',
      ],
    },
  },

  serviceLevelIndicators: {
    loadbalancer: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=true,
      loadBalancerName={ re: 'k8s2-.+-packagecloud-packagecloud-.+' },
      projectId={ re: 'gitlab-(ops|pre)' },
      trafficCessationAlertConfig=false,  // for now until cutover
      additionalToolingLinks=[
        toolingLinks.kibana(title='Packagecloud (prod)', index='packagecloud'),
        toolingLinks.googleLoadBalancer(instanceId='k8s2-um-4zodnh0s-packagecloud-packagecloud-xnkztiio', project='gitlab-ops', titleSuffix=' (prod)'),
        toolingLinks.aesthetics.separator(),
        toolingLinks.kibana(title='Packagecloud (nonprod)', index='packagecloud_pre'),
        toolingLinks.googleLoadBalancer(instanceId='k8s2-um-spdr6cwv-packagecloud-packagecloud-cco5unyp', project='gitlab-pre', titleSuffix=' (nonprod)'),
      ]
    ),
    cloudsql: {
      userImpacting: true,
      description: |||
        Packagecloud uses a GCP CloudSQL MySQL instance. This SLI represents SQL queries executed by the server.
      |||,

      requestRate: gaugeMetric(
        gauge='stackdriver_cloudsql_database_cloudsql_googleapis_com_database_mysql_queries',
        selector={
          database_id: { re: '.+:packagecloud-.+' },
        }
      ),
      significantLabels: ['database_id'],
      serviceAggregation: false,  // Don't include cloudsql in the aggregated RPS for the service
      toolingLinks: [
        toolingLinks.cloudSQL('packagecloud-f05c90f5', 'gitlab-ops'),
      ],
    },
  },
})
