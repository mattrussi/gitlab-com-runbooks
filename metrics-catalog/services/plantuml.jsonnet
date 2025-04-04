local googleLoadBalancerComponents = import './lib/google_load_balancer_components.libsonnet';
local maturityLevels = import 'service-maturity/levels.libsonnet';
local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'plantuml',
  tier: 'sv',
  // plantuml doesn't have a `cny` stage
  serviceIsStageless: true,
  monitoringThresholds: {
    errorRatio: 0.999,
  },
  serviceDependencies: {
  },
  provisioning: {
    kubernetes: true,
    vms: false,
  },
  kubeResources: {
    plantuml: {
      containers: [
        'plantuml',
      ],
    },
  },
  serviceLevelIndicators: {
    loadbalancer: googleLoadBalancerComponents.googleLoadBalancer(
      userImpacting=true,
      loadBalancerName='k8s-um-plantuml-plantuml--58df01f69d082883',  // This LB name seems to be auto-generated, but appears to be stable
      targetProxyName='k8s-tps-plantuml-plantuml--58df01f69d082883',  // This LB name seems to be auto-generated, but appears to be stable
      projectId='gitlab-production',
    ),
  },
  skippedMaturityCriteria: maturityLevels.skip({
    'Service exists in the dependency graph': 'Platuml is a is a stateless web application that generates UML diagrams on the fly. The rendered markdown points to the platuml server in the frontends. It does not interact with any declared services',
  }),
})
