# GKE/Kubernetes Administration

## Rotating Certificate Authority

GKE uses a root [Certificate Authority](https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/) as  the **root of trust**.
This CA is used to sign certificate requests for API server and nodes.
Control plane to node communications as well ass node-to-node communications are protected with TLS and mTLS with the same root of trust.

The cluster root CA has a limited lifetime, after which any certificates signed by the expired CA are invalid.
The cluster credentials should be rotated **manually** before the root CA expires.
If the CA expires and we do not rotate the credentials, the cluster can enter an unrecoverable state!
GKE attempts an automatic credential rotation `30` days before CA expiry.
This automatic rotation ignores maintenance windows and might cause disruptions as GKE recreates nodes to use new credentials.

The GKE CA rotation used to issue new CA valid for 5 years.
We have recently rotated the cluster certificates for regional clusters (
[`gstg`](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17946) and
[`gprd`](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17947)) and they are now valid unitl 2054.
This section serves as a guide for rotationg these CAs in case they are comprised.
It can also be used for rotation the CAs for zonal clusters if needed.

### Steps

- [ ] Set the following variables in your environment

```bash
ENV="..."
GOOGLE_PROJECT="..."
GOOGLE_REGION="..."
CLUSTER_NAME="..."
CLUSTER_VERSION="..."
```

- [ ] Check CA lifetime:

```
gcloud container clusters describe "$CLUSTER_NAME" --project="$GOOGLE_PROJECT" --region="$GOOGLE_REGION" --format="value(masterAuth.clusterCaCertificate)" | base64 --decode | openssl x509 -noout -dates
```

- [ ] Start the rotation:
  - This command causes brief downtime for the cluster API server.

```
gcloud container clusters update "$CLUSTER_NAME" --project="$GOOGLE_PROJECT" --region="$GOOGLE_REGION" --start-credential-rotation
```

- [ ] Verify deployment pipelines are working:
  - [ ] Re-run an existing pipeline for `gprd` cluster [here](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/pipelines).
    - Ensure it will be successfully deployed and all post-merge pipelines will be green.
    - The pipeline will still use the old IP address and CA.

- [ ] Recreate the nodes:
  - [ ] Make sure the version is the same GKE version the cluster already uses.
  - [ ] Get the list of all node pools in the cluster.
    - [ ] `gcloud container node-pools list --project="$GOOGLE_PROJECT" --region="$GOOGLE_REGION" --cluster="$CLUSTER_NAME" --format="value(name)"`
  - [ ] Run the following command for each node pool in your cluster.
    - [ ] `gcloud container clusters upgrade "$CLUSTER_NAME" --project="$GOOGLE_PROJECT" --location="$GOOGLE_REGION" --cluster-version="$CLUSTER_VERSION" --node-pool="..." --async`
  - These operations may take a ver long time depending on how many nodes you have in each node pool.
    You can check the progress of each operation in Google Cloud web console.

- [ ] Run a new pipeline [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/pipelines) with `ENV=gprd`
  - [ ] Ensure the Terraform changes are applied.
  - [ ] Verify the Vault secret is updated with the new API server endpoint and credentials at
        `/shared/kv/kubernetes/clusters/ENV/CLUSTER_NAME` in Vault.

- [ ] Recreate the `vault-k8s-secrets-token` secret:
  - [ ] Run `glsh kube use-cluster NAME`
  - [ ] Run `kubectl get secret vault-k8s-secrets-token --namespace=vault-k8s-secrets --output=json | jq 'del(.data)' | kubectl replace --namespace=vault-k8s-secrets --filename -`

- [ ] Update the *ServiceAccount* JWT token in Vault:
  - [ ] Run `glsh kube use-cluster NAME`
  - [ ] Run `JWT_TOKEN="$(kubectl get secret vault-k8s-secrets-token --namespace vault-k8s-secrets --output jsonpath='{.data.token}' | base64 --decode)"`
  - [ ] Run `glsh vault proxy`
  - [ ] Run `vault login -method oidc`
  - [ ] Run `vault kv put ci/ops-gitlab-net/gitlab-com/gl-infra/config-mgmt/vault-production/kubernetes/clusters/ENV/CLUSTER_NAME service_account_jwt="$JWT_TOKEN"`
  - [ ] Verify the Vault secret is updated with the new service token at
        `/ci/kv/ops-gitlab-net/gitlab-com/gl-infra/config-mgmt/vault-production/kubernetes/clusters/ENV/CLUSTER_NAME` in Vault.

- [ ] Run a new pipeline [here](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/pipelines) with `ENV=vault-production`
  - [ ] Ensure the Terraform changes are applied.

- [ ] Once again, verify deployment pipelines are working:
  - [ ] Re-run an existing pipeline for `gprd` cluster [here](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/pipelines).
    - Ensure it will be successfully deployed and all post-merge pipelines will be green.
    - The pipeline will now use the new IP address and CA.

- [ ] Complete the rotation:
  - This command might cause a brief downtime for the cluster's API server.

```
gcloud container clusters update "$CLUSTER_NAME" --project="$GOOGLE_PROJECT" --region="$GOOGLE_REGION" --complete-credential-rotation
```

- [ ] Once again check CA lifetime and verify it is renewed:

```
gcloud container clusters describe "$CLUSTER_NAME" --project="$GOOGLE_PROJECT" --region="$GOOGLE_REGION" --format="value(masterAuth.clusterCaCertificate)" | base64 --decode | openssl x509 -noout -dates
```

- [ ] Update client credentials:
  - [ ] Run `glsh kube setup` from `runbooks` repo.
  - [ ] Run `glsh kube use-cluster gprd`.
  - [ ] Run `kubectl get nodes`.

- [ ] Finally, verify deployment pipelines are working:
  - [ ] Re-run an existing pipeline for `gprd` cluster [here](https://ops.gitlab.net/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/pipelines).
    - Ensure it will be successfully deployed and all post-merge pipelines will be green.
    - The pipeline will now use the new IP address and CA.

- [ ] Post a message in [#infrastructure-lounge](https://gitlab.enterprise.slack.com/archives/CB3LSMEJV) channel and
      ask people to run the `glsh kube setup` command from the `runbooks` repo.
