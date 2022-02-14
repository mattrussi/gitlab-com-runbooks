// kubeLabelSelector allows services in the metrics-catalog
// to define a set of kubernetes resources that belong to the
// service.
// ```jsonnet
// kubeConfig: {
//    labelSelectors: kubeLabelSelectors(
//      ingressSelector={ namespace: "monitoring" },
//    )
// },
// ```
// In the example above, the service will include all ingresses in the
// namespace "monitoring". These will be included for monitoring, alerting
// and charting purposes.
//
// This functionality relies on kube_state_metrics, which will create
// kube_<resource>_label metrics for each resource. The metrics have
// label_<kube_label> labels on them. This allows us to match Kubernetes
// label to services, using PromQL selector syntax.
//
// Ideally, these selectors will be standardized on `type`, `shard`, etc
// but there are still a lot of exceptions, and this appproach
// allows us to flexibly include and exclude resources.
//
// See https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/15208

// Special default value placeholder
local defaultValue = { __default__: true };

function(

  podSelector=defaultValue,
  hpaSelector=defaultValue,
  nodeSelector=null,  // by default we don't define service fleets
  ingressSelector=defaultValue,
  deploymentSelector=defaultValue,

  podStaticLabels=defaultValue,
  hpaStaticLabels=defaultValue,
  nodeStaticLabels=defaultValue,
  ingressStaticLabels=defaultValue,
  deploymentStaticLabels=defaultValue,
)
  {
    init(type, tier)::
      local defaultSelector = { type: type };
      local defaultStaticLabels = { type: type, tier: tier };
      {
        pod: if podSelector == defaultValue then defaultSelector else podSelector,
        hpa: if hpaSelector == defaultValue then defaultSelector else hpaSelector,
        node: nodeSelector,
        ingress: if ingressSelector == defaultValue then defaultSelector else ingressSelector,
        deployment: if deploymentSelector == defaultValue then defaultSelector else deploymentSelector,

        staticLabels:: {
          pod: if podStaticLabels == defaultValue then defaultStaticLabels else podStaticLabels,
          hpa: if hpaStaticLabels == defaultValue then defaultStaticLabels else hpaStaticLabels,
          node: if nodeStaticLabels == defaultValue then defaultStaticLabels else nodeStaticLabels,
          ingress: if ingressStaticLabels == defaultValue then defaultStaticLabels else ingressStaticLabels,
          deployment: if deploymentStaticLabels == defaultValue then defaultStaticLabels else deploymentStaticLabels,
        },
      },
  }
