**Accessing Kubernetes Clusters**

[[_TOC_]]


# Summary

_Note: Before starting an on-call shift, be sure you follow these setup
instructions_

Majority of our Kubernetes configuration is managed using these projects:

* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common
   * A dependency of the helmfile repositories above.
* https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/tanka-deployments

:warning: CI jobs are executed on the ops instance. :warning:

:warning: Deployer makes changes to the cluster config outside of git, but using pipelines in these projects. This means that the state of the cluster is often not reflected in the projects linked above. However, it usually should be possible to trace down the CI job that applied the change. :warning:

They include CI jobs that apply the relevant config to the right cluster. Most of what we do does not require interacting with clusters directly, but instead making changes to code in these projects.

# Kubernetes API Access

Certain diagnostic steps can only be performed by interacting with kubernetes directly. For this reason you need to be able to run kubectl commands. Remember to avoid making any changes to the clusters config outside of git!

We use private GKE clusters, with the control plane only accessible from within the cluster's VPC. There are two recommended ways for accessing kubernetes api:
- from "console servers"
- using tunnels that go through "console servers"

## Accessing clusters via console servers

:warning: Do not perform any of these actions using the `root` user, nor `sudo` :warning:

Perform the below work on the appropriate `console` server

* `gstg` - `console-01-sv-gstg.c.gitlab-staging-1.internal`
* `gprd` - `console-01-sv-gprd.c.gitlab-production.internal`

- [ ] Authenticate with `gcloud`

```bash
$ gcloud auth login
```

> If you see warnings about permissions issues related to `~/.config/gcloud/*`
> check the permissions of this directory.  Simply change it to your user if
> necessary: `sudo chown -R $(whoami) ~/.config`

You'll be prompted to accept that you are using the `gcloud` on a shared
computer and presented with a URL to continue logging in with, after which
you'll be provided a code to pass into the command line to complete the
process.  By default, `gcloud` will configure your user within the same project
configuration for which that `console` server resides.

- [ ] Get the credentials for production and staging:

```bash
$ gcloud container clusters get-credentials gstg-gitlab-gke --region us-east1 --project gitlab-staging-1
$ gcloud container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```

This should add the appropriate context for `kubectl` to `~/.kube/config`, so the following should
work and display the nodes running on the cluster:

- [ ] `kubectl get nodes`

Running `gcloud auth revoke` (among other things) removes the kubernetes credentials (it wipes them from the `~/.kube/config` file undoing the `get-credentials` command).

**:warning: It is not the intention of the console servers to utilize the `k-ctl`
script or any of the components necessary.  These servers provide the sole means
of troubleshooting a misbehaving cluster or application.  Any changes that
involve the use of `helm` or `k-ctl` MUST be done via the repo and CI/CD.
:warning:**

## Accessing clusters locally (workstation set up for tunneling) ##

GKE clusters must be accessed through the console servers, but they are best accessed using an ssh tunnel. We will access the clusters this way until this issues in the [access epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/337) are completed.

There are two mechanisms you can use to access these clusters via ssh tunnel.

* [`sshuttle`](https://github.com/sshuttle/sshuttle) automates the process of setting up an ssh tunnel _and_ modifying your local route table to forward traffic to the configured CIDR.

* Using a standard ssh socks proxy listening locally to forward requests over the ssh tunnel to their destination

### Using `sshuttle` ###

You might want to use a tool like [`kubectx`](https://github.com/ahmetb/kubectx) or [`kubie`](https://github.com/sbstp/kubie) to smooth
the process of switching kubernetes contexts and namespaces.

Perform the below on your workstation:

- [ ] Get the credentials for the clusters

```bash
# Staging zonal cluster
$ gcloud container clusters get-credentials gstg-us-east1-b --region us-east1-b --project gitlab-staging-1
$ gcloud container clusters get-credentials gstg-us-east1-c --region us-east1-c --project gitlab-staging-1
$ gcloud container clusters get-credentials gstg-us-east1-d --region us-east1-d --project gitlab-staging-1

# Production zonal cluster
$ gcloud container clusters get-credentials gprd-us-east1-b --region us-east1-b --project gitlab-production
$ gcloud container clusters get-credentials gprd-us-east1-c --region us-east1-c --project gitlab-production
$ gcloud container clusters get-credentials gprd-us-east1-d --region us-east1-d --project gitlab-production

# Production regional cluster
$ gcloud container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```

- [ ] Create sshuttle wrappers for initiating tunneled connections

```bash
# kubectl config use-context gke_gitlab-production_us-east1-b_gprd-us-east1-b
$ sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '35.185.25.234/32'

# kubectl config use-context gke_gitlab-production_us-east1-c_gprd-us-east1-c
$ sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '34.75.253.130/32'

# kubectl config use-context gke_gitlab-production_us-east1-d_gprd-us-east1-d
$ sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '34.73.149.139/32'

# kubectl config use-context gke_gitlab-staging-1_us-east1-b_gstg-us-east1-b
$ sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.74.13.203/32'

# kubectl config use-context gke_gitlab-staging-1_us-east1-c_gstg-us-east1-c
$ sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '35.237.127.243/32'

# kubectl config use-context gke_gitlab-staging-1_us-east1-d_gstg-us-east1-d
$ sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '35.229.107.91/32'

# kubectl config use-context gke_gitlab-staging-1_us-east1_gstg-gitlab-gke
$ sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.73.144.43/32'

# kubectl config use-context gke_gitlab-production_us-east1_gprd-gitlab-gke
$ sshuttle -r console-01-sv-gprd.c.gitlab-production.internal '35.243.230.38/32'
```

- [ ] Ensure you can list pods in one of the regions

```bash
$ sshuttle -r console-01-sv-gstg.c.gitlab-staging-1.internal '34.73.144.43/32'
$ kubectl config use-context gke_gitlab-staging-1_us-east1_gstg-gitlab-gke
$ kubectl get pods -n gitlab
```

**Note**: Optionally you rename your context to something less unwieldy: `kubectl config rename-context gke_gitlab-production_us-east1_gprd-gitlab-gke gprd`

### Using ssh socks proxy ###

- [ ] Get credentials for the clusters

```bash
# Staging zonal clusters
$ gcloud container clusters get-credentials gstg-us-east1-b --region us-east1-b --project gitlab-staging-1
$ gcloud container clusters get-credentials gstg-us-east1-c --region us-east1-c --project gitlab-staging-1
$ gcloud container clusters get-credentials gstg-us-east1-d --region us-east1-d --project gitlab-staging-1

# Production zonal clusters
$ gcloud container clusters get-credentials gprd-us-east1-b --region us-east1-b --project gitlab-production
$ gcloud container clusters get-credentials gprd-us-east1-c --region us-east1-c --project gitlab-production
$ gcloud container clusters get-credentials gprd-us-east1-d --region us-east1-d --project gitlab-production

# Production regional cluster
$ gcloud container clusters get-credentials gprd-gitlab-gke --region us-east1 --project gitlab-production
```

- [ ] SSH to a console node depending on the environment and setup a socks proxy

```bash
# for staging
$ ssh -N -D1881 console-01-sv-gstg.c.gitlab-staging-1.internal

# for production
$ ssh -N -D1881 console-01-sv-gprd.c.gitlab-production.internal
```

- [ ] In another window, export the `HTTP_PROXY` environment variable and test connection

```bash
$ export HTTP_PROXY=socks5://localhost:1881
$ kubectl config use-context gke_gitlab-staging-1_us-east1-d_gstg-us-east1-d
$ kubectl get pods -n gitlab
```

### GUI consoles and metrics

When troubleshooting issues, it can often be helpful to have a graphical overview of resources within the cluster, and basic metric data.
For more detailed and expansive metric data, we have a number of [dashboards within Grafana](https://dashboards.gitlab.net/dashboards/f/kubernetes/kubernetes).
For either tunneling mechanism above, one excellent option for a local graphical view into the clusters that works with both is the [Lens IDE](https://k8slens.dev/).
Alternatively, the [GKE console](https://console.cloud.google.com/kubernetes) provides access to much of the same information via a web browser, as well.

# Shell access to nodes and pods

## Accessing a node

* [ ] Initiate an SSH connection to one of the production nodes, this requires a fairly recent version of gsuite

```bash
$ kubectl get pods -o wide  # find the name of the node that you want to access
$ gcloud compute --project "gitlab-production" ssh <node name> --tunnel-through-iap
```

* [ ] From the node you can list containers, and get shell access to a pod as root.  At this writing our nodepools run a mix of docker and containerd, but eventually we expect them to be all containerd.

When using the code snippets below on docker nodes, change `crictl` to `docker`; they are functionally mostly equivalent for common basic tasks.

To quickly see if a node is running docker without explicitly looking it up, run `docker ps`; any containers listed in the outpu means it is a docker node, and empty output means containerd

```bash
$ crictl ps
$ crictl exec -u root -it <container> /bin/bash
```

* [ ] You shouldn't install anything on the GKE nodes. Instead, use toolbox to troubleshoot problems, for example run strace on a process running in one of the GitLab containers. You can install anything you want in the toolbox container.

```bash
$ gcloud compute --project "gitlab-production" ssh <node name>
$ toolbox
```

for more documentation on toolbox see: https://cloud.google.com/container-optimized-os/docs/how-to/toolbox

for more troubleshooting tips see also: https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/k8s-operations.md#attaching-to-a-running-container

## Accessing a pod

* [ ] Initiate an interactive shell session in one of the pods. Bear in mind, that many containers do not include a shell which means you won't be able to access them in this way.

```bash
$ kubectl exec -it <pod_name> -- sh
```

# Running kubernetes config locally

There are certain scenarios in which you might want to evaluate our kubernetes config locally. One such scenario is during an incident, when the CI jobs are unable to run. Another is during development, when you want to test the config against a local cluster such as minikube or k3d.

In order to be able to run config locally, you need to install tools from the projects with kubernetes config linked above.

## Install tools

- [ ] Checkout repos from all projects
- [ ] Install tools from them. They contain `.tool-versions` files which should be used with `asdf`, for example: `cd gitlab-helmfiles; asdf install`
- [ ] Install helm plugins by running the script https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/common/-/blob/master/bin/install-helm-plugins.sh
   - You'll want to run this with the version of helm used by gitlab-com /
     gitlab-helmfiles "active". If you're using asdf, you can achieve this by
     running the script from inside one of the helmfile repos.

## Workstation setup for k-ctl

* [ ] Get the credentials for the pre-prod cluster:

```bash
$ gcloud container clusters get-credentials pre-gitlab-gke --region us-east1 --project gitlab-pre
```

* [ ] Setup local environment for `k-ctl`

These steps walk through running `k-ctl` against the preprod cluster but can also be used to connect to any of the staging or production clusters using sshuttle above.
It is probably very unlikely you will need to make a configuration change to the clusters outside of CI, follow these instructions for the rare case this is necessary.
`k-ctl` is a shell wrapper used by the [k8s-workloads/gitlab-com](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com) over `helmfile`.

```bash
$ git clone git@gitlab.com:gitlab-com/gl-infra/k8s-workloads/gitlab-com
$ cd gitlab-com
$ export CLUSTER=pre-gitlab-gke
$ export REGION=us-east1
$ ./bin/k-ctl -e pre list
```

You should see a successful output of the helm objects as well as custom Kubernetes objects managed by the `gitlab-com` repository.

Note that if you've renamed your kube contexts to something less unwieldy, you
can make the wrapper use your current context:

```bash
$ kubectl config use-context pre
$ FORCE_KUBE_CONTEXT=1 ./bin/k-ctl -e pre list
```

* [ ] Make a change to the preprod configuration and execute a dry-run
```bash
$ vi releases/gitlab/values/pre.yaml.gotmpl
# Make a change
./bin/k-ctl -e pre -D apply
```

# Getting or setting HAProxy state for the zonal clusters

It's possible to drain and stop connections to an entire zonal cluster.
This should be only done in extreme circumstances where you want to stop traffic to an entire availability zone.

* [ ] Get the server state for the production `us-east1-b` zone

_Use the `bin/get-server-state` script in [chef-repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo/)_

```bash
$ ./bin/get-server-state gprd gke-us-east1-b
```

`./bin/set-server-state` is used to set the state, just like any other server in an HAProxy backend
