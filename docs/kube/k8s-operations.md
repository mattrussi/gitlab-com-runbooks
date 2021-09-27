[[_TOC_]]

# GitLab

https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com

## Setup for the oncall

**!Important!** Before you do anything in this doc please follow the [setup instructions for the oncall](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-oncall-setup.md).

## Application Upgrading

* [CHART_VERSION](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/tree/master#setting-chart-version)
  sets the version of the GitLab helm chart
* For individual services see the project [README](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/#services)

## Creating a new node pool

Creating a new node pool will be necessary if we need to change the instance sizes of our nodes or any setting that requires nodes to be stopped.
It is possible to create a new pool without any service interruption by migrating workloads.
The following outlines the procedure, note that when doing this in production you should create a change issue, see https://gitlab.com/gitlab-com/gl-infra/production/issues/1192 as an example.

**Note**: When creating a new node pool to replace an existing node pool, be sure to use the same [`type`](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/-/blob/c33ca88c65a7be73f946c750a6eb988b2a982b12/environments/gprd/gke-regional.tf#L172) for pod scheduling.

```
OLD_NODE_POOL=<name of old pool>
NEW_NODE_POOL=<name of new pool>
```

* Add the new node pool to Terraform by creating a new entry in the relevant TF environment, for example for staging you'd add an entry [here](https://ops.gitlab.net/gitlab-com/gitlab-com-infrastructure/-/blob/master/environments/gstg/gke-zonal.tf#L47).
* Apply the change and confirm the new node pool is created
* Cordon the existing node pool

```bash
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=$OLD_NODE_POOL -o=name); do \
  kubectl cordon "$node"; \
  read -p "Node $node cordoned, enter to continue ..."; \
done

```

* Evict pods from the old node pool

```bash
for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=$OLD_NODE_POOL -o=name); do \
  kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node"; \
  read -p "Node $node drained, enter to continue ..."; \
done
```

* Delete the old node pool manually (in GCP console or on the command line)
* Remove all node pools from the Terraform state

```bash
tf state rm module.gitlab-gke.google_container_node_pool.node_pool[0]
tf state rm module.gitlab-gke.google_container_node_pool.node_pool[1]
```

* Import the new node pool into Terraform

```
tf import module.gitlab-gke.google_container_node_pool.node_pool[0] gitlab-production/us-east1/gprd-gitlab-gke/$NEW_NODE_POOL
```

- Update Terraform so that the new node pool is the only one in the list

## Manual Scaling a Deployment

In times of emergency, whether it be a security issue, identified abuse, and/or an incident where there's great pressure in our infrastructure, it may be necessary to manually set the scale of a Deployment.
When a Deployment is setup with a Horizontal Pod Autoscaler (HPA), and we need to manually scale, be aware that the HPA will fail to autoscale if we scale down to 0 Pods.
Also keep in mind that an HPA will process metrics on a regular cadence, if you scale w/i the window of the HPA configuration, the manual override will quickly be taken over by the HPA.

To scale a deployment, run the following example command:

```
kubectl scale <DEPLOYMENT_NAME> --replicas=<X>
```

Example, scale Deployment `gitlab-sidekiq-memory-bound-v1` to 0 Pods:

```
kubectl scale deployments/gitlab-sidekiq-memory-bound-v1 --replicas=0
```

The `DEPLOYMENT_NAME` represents the Deployment associated and managing the Pods
that are running.  `X` represents the desired number of Pods you wish to run.

After an event is over, the HPA will need at least 1 Pod running in order to
perform its task of autoscaling the Deployment.  For this, we can rerun a
similar command above, using the below as an example:

```
kubectl scale deployments/gitlab-sidekiq-memory-bound-v1 --replicas=1
```

Refer to existing Kubernetes documentation for reference and further details:
* https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
* https://github.com/kubernetes/community/blob/master/contributors/design-proposals/autoscaling/horizontal-pod-autoscaler.md

## Deployment lifecycle

Kubernetes keeps replicasets objects for a limited number of revisions of deployments. Kubernetes events are not created for a replicaset creation/deletion. Only for pods creation/deletion within a replicaset. Similarly, there are no events created for changes to Deployments.

The most complete source of information about changes in kubernetes clusters is the audit log that in GKE is enabled by default. To access audit log, go to Logs Explorer (Stackdriver) in the relevant project in the GCP console.

### diff between deployment versions

An example of how you can get a diff between different deployment versions using rollout history (revisions have to exist in the cluster)
```
$ kubectl -n gitlab rollout history deployment/gitlab-gitlab-shell  # get all deployment revisions
$ kubectl -n gitlab rollout history deployment/gitlab-gitlab-shell --revision 22 > ~/deployment_rev22  # get deployment yaml at rev 22
$ kubectl -n gitlab rollout history deployment/gitlab-gitlab-shell --revision 21 > ~/deployment_rev21  # get deployment yaml at rev 21
```

You can also find the diff in the body of the patch request sent to the apiserver. These are logged in the audit logs. You can find these events with this search:
```
protoPayload.methodName="io.k8s.apps.v1.deployments.patch"
```

### timestamp of a change to Deployment

Check our deployment pipelines on the ops instance, in the projects holding kubernetes config.

If the ReplicaSet objects still exist, you can look at their creation timestamp in their definition.

Audit log also contains a lot of useful information. For example, deployment patching events (e.g. on image update):
```
protoPayload.methodName="io.k8s.apps.v1.deployments.patch"
```

Replicaset creation (e.g. on image update):
```
protoPayload.methodName="io.k8s.apps.v1.replicasets.create"
```

## Attaching to a running container

Keep in mind that the below steps are operating on a production node and
production container which may be servicing customer traffic.  Some
troubleshooting may incur performance penalties or expose you and tooling to
Red classified data.  Consider removing the Pod after your work is complete.

### Using Docker/Containerd

At the time of this writing some of our nodepools run containerd, but a few still run docker.  Due to this we'll use a combination of commands, either `docker` or `crictl`; while they are similar to an extent, both have a significantly different UX when performing the below troubleshooting.

Regardless of runtime, we just need the following information:

* target Pod
* container we want to exploit
* node it's running on

Firstly, figure out what node/zone a Pod is running:

```
kubectl get pods -n gitlab -o wide # get the node name
node_name=<NODE_NAME>
zone=$(gcloud compute instances list --filter name=$node_name --format="value(zone)") # get the zone
```

Determine the runtime of that node:

```
kubectl get node $node_name -o json | jq .metadata.labels.\"cloud.google.com/gke-container-runtime\"
```

If using the `containerd` runtime, we now need to figure out the container ID
(for the docker runtime, we'll do this in a bit, for now, skip to ssh'ing into
the node):

```
kubectl get pod $pod_name -o json | jq .status.containerStatuses
```

In the output, if there's multiple containers, find the one you want, followed
by that objects' `containerID`.  This is a very long ID, and we may need it
later.  Note that down, we'll need it later.

SSH into the node:

```
gcloud compute ssh $node_name --zone=$zone --tunnel-through-iap
```

If using the `docker` runtime, we now can get our container ID:

```
docker ps | grep 'websockets-57dbbcdcbd-crv2p'
```

Note that the result will be at least two containers, one using the `pause` image, and others representing each container participating in our target Pod.  [The `pause` image is NOT the one you are looking for.](https://www.ianlewis.org/en/almighty-pause-container)

If the container contains all the tools you need, you can simply exec into it:

```
# docker runtime:
docker exec -it 7aa3c4ad2775c /bin/bash

# containerd runtime:
crictl exec -it 7aa3c4ad2775c /bin/bash
```

Where `7aa3c4ad2775c` is the container id that you have already found.  If it doesn't have `/bin/bash`, try `/bin/sh` or just exec'ing `ls` to find what binaries are available.

At this point we can install some tooling necessary and interrogate the best we can.  Remember that the container could be shutdown at any time by k8s, and any changes are very transient.

If you need more when operating against the container, examples include needing a root shell or perhaps a tool you need does not exist on the image, you can attach another container to the same network/pid namespaces when running.  For nodes utilizing the `docker` runtime, you can utilize the below.  For runtimes using `containerd`, skip ahead.

```
docker run \
  -it \
  --pid=container:k8s_sidekiq_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0 \
  --net=container:k8s_sidekiq_gitlab-sidekiq-export-966444c8-sbpj5_gitlab_148e5cfb-21a2-11ea-b2f5-4201ac100006_0 \
  --cap-add sys_admin \
  --cap-add sys_ptrace \
  ubuntu /bin/bash
```

In the above example we attached an ubuntu container running `bash` to the sidekiq container.  This will be a read-only filesystem (unlike the `exec` case above)

For the `containerd` runtime we can pop directly onto the container as root:

```
runc --root /run/containerd/runc/k8s.io/ \
  exec \
  -t \
  -u 0 \
  $container_id \
  /bin/bash
```

Or use whatever shell you know is readily available.  Note you need the entire
container ID that you had found earlier, unlike docker who accepts shorter IDs,
`runc` will toss you an error that the container does not exist if a shortened
ID is utilized.  Note we are using `runc` here, as `crictl` does not provide us
this capability.  `runc` is the underlying runtime, `containerd` is how
Kubernetes interfaces with it.

### Using Toolbox

GKE nodes by design have a very limited subset of tools. If you need to conduct troubleshooting directly on the host, consider using toolbox. Toolbox is a container that is started with the host's root filesystem mounted under `/media/root/`.
The toolbox's file system is available on the host at `/var/lib/toolbox/`.

You can specify which container image you want to use, for example you can use `coreos/toolbox` or build and publish your own image.
There can only be one toolbox running on a host at any given time.

For more details see: https://cloud.google.com/container-optimized-os/docs/how-to/toolbox

### Debugging containers in pods

Quite often you'll find yourself working with containers created from very small images that are stripped of any tooling. Installation of tools inside of those containers might be impossible or not recommended. Changing the definition of the pod (to add a debug container) will result in recreation of the pod and likely rescheduling of the pod on a different node.

One way to workaround it is to investigate the container from the host. Below are a few ideas to get you started.

#### Run a command with the pod's network namespace

1. Find the PID of any process running inside the pod, you can use the pause process for that (network namespace is shared by all processes/containers in a pod). There are many, many ways to get the PID, here are a few ideas:
    1. get PID of a process running in a `containerd` container:
        1. List containers and get container ID: `crictl ps -a`
        1. Get pid of a process in a container with a given ID: `crictl inspect <containerID>` search for `info.pid` field
    1. get PIDs and hostnames of all containers running in docker: `docker ps -a | tail -n +2 | awk '{ print $1}' | xargs docker inspect -f '{{ .State.Pid }} {{ .Config.Hostname }}'`
1. Run a command with the process' namespace
    1. Entire toolbox started with the given namespace
        1. `toolbox --network-namespace-path=/proc/<container_pid>/ns/net`
    1. Run a single command in toolbox with the given namespace
        1. Once you have the PID, link its namespace where the `ip` command can find it (by default docker doesn't link network namespaces that it creates): `ln -sf /proc/<pid_you_found>/ns/net /var/run/netns/<your_custom_name>`
        1. Enter toolbox: `toolbox`
        1. List namespaces: `ip netns list`
        1. Run your command with the desired network namespace: `ip netns exec <your_custom_name> ip a`
    1. Alternatively, you can use nsenter on the GKE host (note: it proved difficult to run it with toolbox): `nsenter -target <PID> -mount -uts -ipc -net -pid`

#### Start a container that will use network and process namespaces of a pod

Only available for docker, not containerd:

1. Get container id from PID: `cat /proc/<PID>/cgroup`
1. Get container name from container id: `docker inspect --format '{{.Name}}' "<containerId>" | sed 's/^\///'`
1. Create a container on the host: `docker run --rm -ti --net=container:<container_name> --pid=container:<container_name> --name ubuntu ubuntu bash`

For example:
```
$ docker run --rm --name pause --hostname pause gcr.io/google_containers/pause-amd64:3.0   # this is an example, it will run a simple container which you will connect to in a moment
$ docker run --rm -ti --net=container:pause --pid=container:pause -v /:/media/root:ro --name ubuntu ubuntu bash  # this will run an ubuntu container with network and process namespaces from the pause container and host's root file system mounted under /media/root
```

#### Share process namespace between containers in a pod

Share process namespace between containers in a pod: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

## Auto-scaling, Eviction and Quota

### Nodes

* Node auto-scaling: https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-autoscaler

Node auto-scaling is part of GKE's cluster auto-scaler, new nodes will be added
to the cluster if there is not enough capacity to run pods.

The maximum node count is set as part of the cluster configuration for the
[node pool in Terraform](https://gitlab.com/gitlab-com/gitlab-com-infrastructure/blob/7e307d0886f0725be88f2aa5fe7725711f1b1831/environments/gprd/main.tf#L1797)

### Pods

* Pod auto-scaling: https://cloud.google.com/kubernetes-engine/docs/how-to/scaling-apps

Pods are configured to scale by CPU utilization, targeted at `75%`

Example:

```
kubectl get hpa -n gitlab
NAME              REFERENCE                    TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
gitlab-registry   Deployment/gitlab-registry   47%/75%   2         100       21         11d
```

It is possible to scale pods based on custom metric but this is currently not used in the cluster.

### Quota

There is a [dashboard for monitoring the workload quota for production](https://dashboards.gitlab.net/d/kubernetes-resources-workload/kubernetes-compute-resources-workload?orgId=1&refresh=10s&var-datasource=Global&var-cluster=gprd-gitlab-gke&var-namespace=gitlab&var-workload=gitlab-registry&var-type=deployment) that shows the memory quota.

The memory threshold is configures in the [kubernetes config for Registry](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/blob/4b7ba9609f634400e500b3ac54aa51240ff85b27/gprd.yaml#L6)

If a large number of pods are being evicted it's possible that increasing the
requests will help as it will ask Kubernetes to provision new nodes if capacity
is limited.

Kubernetes Resource Management: https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/

## Profiling in kubernetes

### SSH to a GKE node

```bash
$ kubectl -n pubsubbeat get pods -o wide  # find the node hosting the pod with the container you want to profile
pubsubbeat-pubsub-praefect-inf-gprd-d6ddcf5bb-7lrgv               3/3     Running   0          20m   10.222.56.148   gke-gprd-gitlab-gke-git-https-1-29f46e3d-4fmr         <none>           <none>
pubsubbeat-pubsub-puma-inf-gprd-68dcc4fc7-ddwcb                   3/3     Running   0          20m   10.222.5.110    gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-ptgj   <none>           <none>
pubsubbeat-pubsub-rails-inf-gprd-788c4c5f59-p74rk                 3/3     Running   0          19m   10.222.8.89     gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q   <none>           <none>
(...)
$ gcloud beta compute ssh --zone "us-east1-c" "gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q" --project "gitlab-production"  # ssh to the GKE node
```

### Check for presence of symbols

```bash
$ CONTAINER_ID=$(docker ps | grep pubsubbeat_pubsubbeat-pubsub-rails | awk '{print $1}')  # Find the ContainerID of the container you want to profile
$ docker container top $CONTAINER_ID  # list processes in the container and find the path of the binary
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                2932207             2932188             0                   14:28               ?                   00:00:00            /bin/sh -c /bin/pubsubbeat -c /etc/configmap/pubsubbeat.yml -e 2>&1 | /usr/bin/rotatelogs -e /volumes/emptydir/pubsubbeat.log 50M
root                2932237             2932207             99                  14:28               ?                   03:05:29            /bin/pubsubbeat -c /etc/configmap/pubsubbeat.yml -e
root                2932238             2932207             0                   14:28               ?                   00:00:00            /usr/bin/rotatelogs -e /volumes/emptydir/pubsubbeat.log 50M
$ CONTAINER_ROOTFS="$(docker inspect --format="{{ .GraphDriver.Data.MergedDir }}" $CONTAINER_ID)"  # find the path to the root fs of the container
$ sudo file "$CONTAINER_ROOTFS/bin/pubsubbeat"  # check if the binary contains symbols, the last column should say: "not stripped"
/var/lib/docker/overlay2/2d9bc0cc996455ae6adc02b8681d4136135ab3fc93a89514bb6aa204e1d63233/merged/bin/pubsubbeat: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=dj2P7xQg9cLDu7_yJhYO/nEBeM2i2MX7nGA4gEyTu/oWmkQmXlToiIjtBSa6lZ/eWGiKNvzpYh2Ftm14MGU, not stripped
```

### Collect `perf record` data

#### on the entire node

```bash
$ sudo perf record -a -g -e cpu-cycles --freq 99 -- sleep 60
```

#### on a single container

If the binary running in the container doesn't contain symbols, the data you collect will include empty function names (will not provide a lot of value).

```bash
$ CONTAINER_ID=$(docker ps | grep pubsubbeat_pubsubbeat-pubsub-rails | awk '{print $1}')  # Find the ContainerID of the container you want to profile
$ CONTAINER_CGROUP=$(docker inspect --format='{{ .HostConfig.CgroupParent }}' $CONTAINER_ID)  # Find the cgroup of the container
$ sudo perf record -a -g -e cpu-cycles --freq 99 --cgroup $CONTAINER_CGROUP -- sleep 60
```

### Extract stacks from `perf record` data with `perf script`

```bash
$ sudo perf script --header | gzip > stacks.$(hostname).$(date +'%Y-%m-%d_%H%M%S_%Z').gz
```

### Download `perf script` output

So that we avoid installing additional tooling on the GKE node.

On your localhost:
```bash
$ gcloud beta compute scp --zone "us-east1-c" "gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q:stacks.gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q.2021-03-05_173617.gz" --project "gitlab-production" .
$ gunzip stacks.gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q.2021-03-05_173617.gz
```

### Visualize using Flamescope

```bash
$ docker run -d --rm -v $(pwd):/profiles:ro -p 5000:5000 igorwgitlab/flamescope  # open your browser and go to http://127.0.0.1:5000/
```

### Visualize using Flamegraph

```bash
$ cat stacks.gke-gprd-gitlab-gke-sidekiq-urgent-ot-9be5be8a-o05q.2021-03-05_173617 | stackcollapse-perf.pl --kernel | flamegraph.pl > flamegraph.$(hostname).$(date '+%Y%m%d_%H%M%S_%Z').svg
```
