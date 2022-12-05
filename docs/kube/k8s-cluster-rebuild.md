# Rebuilding a kubernetes cluster

This page is for replacing a zonal cluster, if you seek creating a new cluster on a different region/zone,
please refer to the [create new kubernetes cluster page](/k8s-new-cluster.md)

## 1- Skipping cluster deployment

It's necessary to skip deploying to the cluster when replacing it, this way we don't disrupt the Auto Deploy.

1. Make sure the Auto Deploy pipeline is not active and no active deployment is happening on the environment
2. Identify the name of the cluster we need to skip, and we need to use the full name of the GKE cluster,
for example `gstg-us-east1-b`.
3. Then we need to set the environment variable `CLUSTER_SKIP` to the name of the cluster `gstg-us-east1-b` for instance. This needs to be
placed on the ops instance where [the pipelines run](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/settings/ci_cd).
4. Don't forget to remove the variable after the maintenance window closes and the cluster is replaced.

## 2- Removing traffic

1. Create a silence on [alerts.gitlab.net](https://alerts.gitlab.net/) using the following example filter:
    - `cluster=gstg-us-east1-b`
2. Pause alerts from [Dead Mans Snitch](deadmanssnitch.com)
   - Find the alert named `Prometheus - GKE <cluster_name>` and hit the pause
     button

### 2.a Removing traffic from canary

We do this so we don't over-saturate canary when the `gstg` cluster goes down, canary doesn't have the same capacity as the main stage.

1. We start with setting all the canary backends to `MAINT` mode

```
$> declare -a CNY=(`./bin/get-server-state -z $ZONE gstg | grep -E 'cny|canary' | awk '{ print substr($3,1,length($3)-1) }' | tr '\n' ' '`)


$> for server in $CNY
do
./bin/set-server-state -f -z $ZONE gstg maint $server
done
```

2. Fetch all canary backends to validate that they are put to `MAINT`

```
$> ./bin/get-server-state -z $ZONE gstg | grep -E 'cny|canary'
```

### 2.b Removing traffic from main stage

1. We now want to remove traffic targeting our main stage for this zone.  The below command will
instruct HAProxies that live in the same zone and sets the backends to `MAINT`:

```
$> declare -a MAIN=(`./bin/get-server-state -z b gstg | grep -I -v -E 'cny|canary'| grep 'us-east1-b' | awk '{ print substr($3,1,length($3)-1) }'| tr '\n' ' '`)

$> for server in $MAIN
do
./bin/set-server-state -f -z b -s 60 gstg maint $server
done
```

2. Fetch all main stage backends to validate that they are put to `MAINT`

```
./bin/get-server-state -z b gstg | grep -I -v -E 'cny|canary'| grep 'us-east1-b'
```

## 3- Replacing cluster using Terraform

### 3.a Setting up the tooling

In order to work with terraform and `config-mgmt` repo, you can refer to the [getting started](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt#getting-started)
to setup the needed tooling and quick overview of the steps needed.

### 3.b Pull latest changes

1. We need to make sure we pulled the latest changes from the `config-mgmt` repository before executing
any command.

### 3.c Executing terraform

This is a two step process, 1 to replace the cluster, the next to recreate the
node pools that were removed.

1. Perform a `terraform plan` to validate cluster recreation:

**Executer should perform a `plan` and validate the changes before running the `apply`**

```
tf plan -replace="module.gke-us-east1-b.google_container_cluster.cluster"
```

You should see:

```
Terraform will perform the following actions:

  # module.gke-us-east1-b.google_container_cluster.cluster will be replaced, as requested
```

2. Then `apply` the cluster recreation change:

```
tf apply -replace="module.gke-us-east1-b.google_container_cluster.cluster"
```

3. Perform an unconstrained `terraform plan` to validate the creation of the
   node pools.

```
tf plan
```

We should see the addition of various node pools.  Refer to the
[`config-mgmt`](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/) repository for details on the node pools we configure at that
moment in time.

If the plan is dirty consider writing a targeted apply as necessary to avoid
change outside of the Change Request related to the cluster rebuild work.

4. Perform a `terraform apply`, leveraging a `target` if required.

```
tf apply [-target=<path/to/node_pool{s}>]
```

### 3.d New cluster configuration setup

After terraform command is executed we will have a brand new cluster, we need to orient our tooling to use
the new cluster.

1. We start with `glsh` we need to run `glsh kube setup` to fetch the cluster configs.
2. Validate we can use the new context and `kubectl` works with the cluster:

```
$> glsh kube setup
$> glsh kube use-cluster gstg-us-east1-b
$> kubectl get pods --all-namespaces
```

3. Update the new cluster's `apiServer` IP to the [tanka repository](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments/-/blob/master/lib/gitlab/clusters.libsonnet)
4. Configure Vault Secrets responsible for CI configurations within `config-mgmt`:

```
CONTEXT_NAME=$(kubectl config current-context)
KUBERNETES_HOST=$(kubectl config view -o jsonpath='{.clusters[?(@.name == "$CONTEXT_NAME")].cluster.server}')
SA_SECRET=$(kubectl --namespace external-secrets get serviceaccount external-secrets-vault-auth -o jsonpath='{.secrets[0].name}')
SA_TOKEN=$(kubectl --namespace external-secrets get secret ${SA_SECRET} -o jsonpath='{.data.token}' | base64 -d)
CA_CERT=$(kubectl --namespace external-secrets get secret ${SA_SECRET} -o jsonpath='{.data.ca\.crt}' | base64 -d)

vault kv put ci/ops-gitlab-net/config-mgmt/vault-production/kubernetes/CLUSTER host="${KUBERNETES_HOST}" ca_cert="${CA_CERT}" token="${SA_TOKEN}"
```

5- From the `config-mgmt/environments/vault-production` repo, we need to run `tf apply` it will show us
that there's config change for the cluster we replaced, then we apply this change so vault knows of the new cluster.

```
cd config-mgmt/environments/vault-production
tf apply
```

## 4.a- Deploying Workloads

First we bootstrap our cluster with required CI configurations:

1. From [gitlab-helmfiles](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles) repo
    1. **pull latest changes**
    1. `cd releases/00-gitlab-ci-accounts`
    1. `helmfile -e gstg-us-east1-b apply`

1. We then need to tend to our Calico management.  Execute the following on the
   new cluster;

```
kubectl -n kube-system annotate cm calico-node-vertical-autoscaler meta.helm.sh/release-name=calico-node-autoscaler
kubectl -n kube-system annotate cm calico-node-vertical-autoscaler meta.helm.sh/release-namespace=kube-system
kubectl -n kube-system label cm calico-node-vertical-autoscaler app.kubernetes.io/managed-by=Helm
```

Then we can complete setup via our existing CI pipelines:

1. From [gitlab-helmfiles](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles) CI Pipelines, find the latest default branch pipeline, and rerun the job associated with the cluster rebuild
1. From [tanka-deployments](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments) CI Pipelines, find the latest default branch pipeline, and rerun the job associated with the cluster rebuild
1. After installing the workloads, run `kubectl get pods --all-namespaces` and check if all workloads are working correctly before going to the next step.

### 4.b Deploy Prometheus Rules

Prometheus has a wide array of recording/alert rules; these must be deployed
otherwise we may fly blind with some of our metrics.

- Browse to [Runbooks CI Pipelines](https://ops.gitlab.net/gitlab-com/runbooks/-/pipelines)
- Find the latest Pipeline executed against the default branch
- Retry the `deploy-rules-{non-}production` job

### 4.c Deploying gitlab-com

- Remove the `CLUSTER_SKIP` variable from [ops instance](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/settings/ci_cd)
- Find the latest pipeline which performed a configuration change to the staging
  environment and replace the job associated with this cluster
  - Note that this will install all releases and configurations but will not
    deploy the correct version of GitLab, that comes in the following step
  - It'll be easiest to find a pipeline from the most recent MR merge vs surfing
    through the Pipeline pages
  - MR's are on: [gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
- Deploy the correct version of GitLab
  - Run the latest successful `auto-deploy` job. Go to the [announcements channel](https://gitlab.slack.com/archives/C8PKBH3M5) and check latest successful job, and re-run the Kubernetes job for the targeted cluster.
- Spot check the cluster to validate the Pods are coming online and remain in a
  Running state
  - Connect to our replaced cluster `glsh kube use-cluster gstg-us-east1-b`
  - `kubectl get pods --namespace gitlab`

### 4.d Verify we run the same version on all clusters

- `glsh kube use-cluster gstg-us-east1-b`
- in a separate window: `kubectl get configmap gitlab-gitlab-chart-info -o jsonpath="{.data.gitlabVersion}"`
- `glsh kube use-cluster gstg-us-east1-c`
- in a separate window: `kubectl get configmap gitlab-gitlab-chart-info -o jsonpath="{.data.gitlabVersion}"`
- Version from cluster `c` matches version from cluster `b`

### 4.e Monitoring

1. In [this dashboard](https://dashboards.gitlab.net/d/kubernetes-kubelet/kubernetes-kubelet?orgId=1&refresh=5m&var-datasource=default&var-cluster=gstg-us-east1-b&var-instance=All)
we should see the numbers of the pods and containers of the cluster.
1. Remove any silences that were created earlier
1. Unpause any alerts from Dead Mans Snitch
1. Validate no alerts are firing related to this replacement cluster on the [Alertmanager](https://alerts.gitlab.net)

## 5- Pushing traffic back to the cluster

- We start with the main stage, we chose zone `b` as an example.

```
$> declare -a MAIN=(`./bin/get-server-state -z b gstg | grep -I -v -E 'cny|canary'| grep 'us-east1-b' | awk '{ print substr($3,1,length($3)-1) }' | tr '\n' ' '`)

$> for server in $MAIN
do
./bin/set-server-state -f -z b -s 60 gstg ready $server
done
```

- Validate all main stage backends are on READY state

```
$> ./bin/get-server-state -z b gstg | grep -I -v -E 'cny|canary'| grep 'us-east1-b'
```

- Then we change canary backends to READY state

```
$> declare -a CNY=(`./bin/get-server-state -z b gstg | grep -E 'cny|canary' | awk '{ print substr($3,1,length($3)-1) }' | tr '\n' ' '`)

$>for server in $CNY
do
./bin/set-server-state -f -z b -s 60 gstg ready $server
done
```

- Validate all canary stage backends are on READY state

```
$> ./bin/get-server-state -z b gstg | grep -E 'cny|canary'
```
