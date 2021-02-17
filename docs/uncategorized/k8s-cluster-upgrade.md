# GKE Cluster Upgrade Procedure

All of our non-gprd GKE clusters are now set to automatically upgrade. They are all
using the [Regular release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels)
and have specific times they will upgrade themselves, as documented [here](https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1137#note_433946309).

We have a cloud function called [gke-notifications](https://gitlab.com/gitlab-com/gl-infra/gke-notifications/)
which will add annotations to Grafana every time a GKE auto upgrade takes place.

Our production clusters are currently the only clusters which need to be upgraded manually.

## Rollback Procedure (or lack thereof)

:warning: Please make sure to read and understand the following :warning:

Due the nature of GKE upgrades, there is unfortunately no ability for us to
rollback. For zonal cluster upgrades if something goes wrong we have the ability
for specific services to stop sending traffic to that entire gke cluster by draining
the affected service backends from haproxy.

If we do ever hit issues which would warrant a rollback, the first step is to
reach out to Google support with a sev 1 issue to attempt to recover the cluster.
In the case of entire catastrophic failure, we can destroy the cluster and
recreate it using terraform (and bootstrap it following instructions at
https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/k8s-new-cluster.md

## Notes about forced upgrades across minor versions
You can look at the release notes for the regular release channel [here](https://cloud.google.com/kubernetes-engine/docs/release-notes-regular)
This is important to follow as when all releases of a specific minor version (e.g. 1.16) are removed
from a channel, the clusters will be automatically upgraded to the next minor release (e.g. 1.17)
during the next maintenance period. This is typically noted in the release notes with a note similar to

> Auto-upgrading control planes upgrade from versions 1.16 and 1.17 to version 1.17.9-gke.1504 during this release.

## Things to take note of when expecting a minor version upgrade
First thing to do is check the Kubernetes release notes for the version in question
[here](https://github.com/kubernetes/kubernetes/tree/master/CHANGELOG). In particular
you should read carefully everything under the following sections

* Known Issues
* Urgent Upgrade Notes
* Deprecations and Removals
* Metrics Changes

Look for anything that might impact APIs, services, or metrics we currently consume.

After a minor upgrade has taken place on a cluster, you should look at all the dashboards
in https://dashboards.gitlab.net that have the Kubernetes tag and check they still work
in the upgraded environment (e.g. no missing metrics)

## Procedure

The following is the procedure to undertake for the GKE cluster in question, and
includes the steps for upgrading both the masters and the individual node pools.
It is safe to use as a basis for the steps in the change request, but might need
to be altered to suit the environment (e.g. steps duplicated for each node pool)

### Step 0.1

The first step is to determine what version of Kubernetes you wish to upgrade
your cluster to. To do so, find the highest patch version of the minor release
your upgrading to, inside the `REGULAR` release channel

```
gcloud --project gitlab-pre container get-server-config --region us-east1 --format json | jq '.channels[] | select(.channel == "REGULAR")'
```

* Copy and paste the below procedure into a Change Request (summary through
  rollback procedure)
  * https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=change_management
* Fill out the necessary details of the Change Request following our [Change
  Management Guidelines]
* Modify any `<Merge Request>` with a link to the merge request associated with
  that step
* Modify `<VERSION>` with the desired version we will be upgrading the GKE
  cluster to

### Step 0.2

* Copy and paste the below sections into a new change request at
  * https://gitlab.com/gitlab-com/gl-infra/production/-/issues/new?issuable_template=change_management
* Fill out the necessary details of the Change Request following our [Change
  Management Guidelines]
* Modify any references to `<CLUSTER>` with the name of the cluster you upgrading
* Modify any `<Merge Request>` with a link to the merge request associated with
  that step
* Modify `<VERSION>` with the desired version we will be upgrading the GKE
  cluster to
* Note for zonal clusters you will need to replace all references to `--region us-east1`
  with `--zone us-east1-b` (if for example, upgrading the zonal cluster in `us-east1-b`)

### Summary

To upgrade our GKE Cluster `<CLUSTER>` to `<VERSION>`.

Part of `<INSERT LINK TO GKE Upgrade Issue>`

### Step 1: Upgrade masters

* [ ] Use the gcloud cli to upgrade the Kubernetes masters only. They
must be done before any of the node pools are done.

```
gcloud --project <PROJECT> container clusters upgrade <CLUSTER> --cluster-version=<VERSION> --master --region us-east1
```

This operation can take up to 40 minutes or so. Once it has been done, you can
confirm the new version is running on the masters by pointing your `kubectl` to
the cluster and running

```
kubectl version
```

Specifically looking for `Server Version`. Remember to be connected to the target cluster.  Instructions for this are [here](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/k8s-oncall-setup.md#accessing-clusters-via-console-servers)

### Step 2: Determine Node Pools to Upgrade

* [ ] First list all the node pools of the cluster

```
gcloud --project <PROJECT> container node-pools list --cluster <CLUSTER> --region us-east1
```

And make a note of the names of all the node pools. Each node pool will need
it's own step documented as below

### Step 3: Upgrade Node Pool <NODE POOL NAME>
* [ ] Upgrade the node pool by running the following command

```
gcloud --project <PROJECT> container clusters upgrade <CLUSTER> --cluster-version=<VERSION> --node-pool <NODE POOL NAME> --region us-east1
```

Note this operation can take multiple hours for a node pool, depending on the
size and workloads running on it.

To confirm the node pool has been upgraded, use `gcloud` to list all the node
pools and look at the `NODE_VERSION` column and confirm the version is correct.

```
gcloud --project <PROJECT> container node-pools list --cluster <CLUSTER> --region us-east1
```

### Step 4: Update terraform references to new minimum version

Now that the cluster and node pools have been upgraded, we need to do an update
in terraform to set the minimum Kubernetes version for that cluster via our
gke modules `kubernetes_version` parameter. This ensures that should the cluster
need to be rebuilt for any reason, it will be be built running the version
that we have upgraded to at minimum.

Open an MR against the terraform repo, for the cluster in question (it's either
in `gke-regional.tf` or `gke-zonal.tf`) to bump the `kubernetes_version`
parameter to the Kubernetes minor version we just upgraded to. E.g. if we just
upgraded to `1.18.12-gke.1206` change the parameter in terraform to `1.18`

* [ ] MR `<Merge Request>` to be applied via terraform to lock cluster to minimum
as new version

## Post upgrade Considerations

Once all clusters have been upgraded to a new version, we should look at all our
kubernetes deployment tooling repositories under https://cloud.google.com/kubernetes-engine/docs/release-notes-regular
and open issues/MRs against them to upgrade the version of `kubectl` they are
using to match the new minor version.
