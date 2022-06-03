# Kubernetes-Agent Disable Integrations

In case of incidents where kas might be inadvertedly be affecting services it
integrates with including API, Gitaly, and Redis, it is possible to temporary
disable these integrations until proper diagnosis and remediation of problems
can occur.

## Disabling access to API

There are multiple ways to do this, but one of the simplest is to use the
[Kubernetes Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
to stop the `kas` pods from being able to access to Gitlab API. To do this
change the helm value `gitlab.kas.networkpolicy.egress.rules` to remove the the
rule that allows access to Gitlab API. e.g. <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl#L1253-1263>
through a merge request and apply to production.

When this access is disabled, all Gitlab users `agentk` agents will be unable
to authenticate to `kas` and thus will be unable to leverage any and all functionality
that `kas` provides.

## Disabling access to Gitaly

If access to all Gitaly nodes needs to be temporarily disabled, this can be done
through changing the [Kubernetes Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
to stop the `kas` pods from being able to access Gitaly.  To do this
change the helm value `gitlab.kas.networkpolicy.egress.rules` to remove the the
rule that allows access to Gitlab API. e.g. <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl#L1264-1277>
through a merge request and apply to production.

When this access is disabled, Gitlab users will be unable to use `agentk`/`kas` for applying
Kubernetes manifests via gitops.

## Disabling access to redis

If access to redis/the `kas` redis integration needs to be temporarily disabled,
the best way to do this is to change the helm value `gitlab.kas.redis.enabled`
to `false`. e.g. <https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/values.yaml.gotmpl#L1228>
through a merge request and apply to production.

When this is disabled, it would stop `kas` from being able to do IP and token
based rate limiting, instead falling back to a global rate limit for all operations
which might bottleneck users.
