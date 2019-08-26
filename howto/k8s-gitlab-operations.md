## Workstation setup for the oncall

Configuration changes are handled through GitLab CI so most of what we do does
not require interacting with the cluster directly. As an oncall SRE, you should
also setup your workstation to query the kubernetes API with `kubectl`.

- [ ] Get the credentials for production, staging and preprod:

```
gcloud beta container clusters get-credentials pre-gitlab-gke --region us-east1 --project gitlab-pre
gcloud beta container clusters get-credentials gstg-gitlab-gke --region us-east1 --project gitlab-staging-1
gcloud beta container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```

- [ ] Install `kubectl` https://kubernetes.io/docs/tasks/tools/install-kubectl/
- [ ] Install `helm` https://helm.sh/docs/using_helm/#install-helm
- [ ] Install `kubectx` https://github.com/ahmetb/kubectx
- [ ] Test to ensure you can list the installed helm charts in staging and production
```
cd /path/to/gl-infra/k8s-workloads/gitlab-com
./bin/k-ctl -e gstg list
./bin/k-ctl -e gprd list
```
- [ ] Get the current horizontal pod autoscaler status for production
```
kubectl -n gitlab get hpa
```

## Common operations

## Auto-scaling and Eviction

### Nodes

* Node auto-scaling: https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler

Node auto-scaling is part of GKE's cluster auto-scaler, new nodes will be added
to the cluster if there is not enough capacity to run pods.

The maximum node count is set as part of the cluster configuration
for the
[node pool in terraform](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/blob/7e307d0886f0725be88f2aa5fe7725711f1b1831/environments/gprd/main.tf#L1797)

### Pods

* Pod auto-scaling: https://cloud.google.com/kubernetes-engine/docs/how-to/scaling-apps

Pods are configured to scale by CPU utilization, targeted at `75%`

Example:
```
kubectl get hpa -n gitlab
NAME              REFERENCE                    TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
gitlab-registry   Deployment/gitlab-registry   47%/75%   2         100       21         11d
```

It is possible to scale pods based on custom metric but this is currently not
used in the cluster.

### Eviction

* Configuration for eviction when pods are out of resources https://kubernetes.io/docs/tasks/administer-cluster/out-of-resource/

There is a
[dashboard for monitoring the workload quota for production](https://dashboards.gitlab.net/d/kubernetes-resources-workload/kubernetes-compute-resources-workload?orgId=1&refresh=10s&var-datasource=Global&var-cluster=gprd-gitlab-gke&var-namespace=gitlab&var-workload=gitlab-registry&var-type=deployment)
and the threshold is configured in the
[kubernetes config for Registry](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/4b7ba9609f634400e500b3ac54aa51240ff85b27/gprd.yaml#L6)
