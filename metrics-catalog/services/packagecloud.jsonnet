local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

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
      loadBalancerName='k8s2-um-4zodnh0s-packagecloud-packagecloud-xnkztiio',
      projectId='gitlab-ops',
      additionalToolingLinks=[
        toolingLinks.kibana(title='Packagecloud', index='packagecloud'),
      ],
      extra={
        severity: 's3',  // don't page anyone yet
      }
    ),
    loadbalancer_nonprod: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=false,
      trafficCessationAlertConfig=false,
      loadBalancerName='k8s2-um-spdr6cwv-packagecloud-packagecloud-cco5unyp',
      projectId='gitlab-pre',
      additionalToolingLinks=[
        toolingLinks.kibana(title='Packagecloud', index='packagecloud_pre'),
      ],
      extra={
        severity: 's3',  // never page as it's non-prod
      }
    ),
  },
})
