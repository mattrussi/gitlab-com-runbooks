# Redis on Kubernetes

## CPU profiling

In order to collect a CPU profile for redis, you need to SSH into the node and run `perf_flamegraph_for_all_running_processes.sh`.

List nodes:

```
➜  ~ gcloud --project gitlab-pre compute instances list --filter 'name:gke-pre-gitlab-gke-redis'
NAME                                                 ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP   EXTERNAL_IP  STATUS
gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc  us-east1-b  c2-standard-8               10.232.20.65               RUNNING
gke-pre-gitlab-gke-redis-ratelimiting-b9fd9cef-42t5  us-east1-c  c2-standard-8               10.232.20.41               RUNNING
gke-pre-gitlab-gke-redis-ratelimiting-3378c320-7uwa  us-east1-d  c2-standard-8               10.232.20.16               RUNNING
gke-pre-gitlab-gke-redis-ratelimiting-3378c320-h1j3  us-east1-d  c2-standard-8               10.232.20.67               RUNNING
```

or

```
$ kubectl get nodes | grep -e 'NAME' -e 'redis-ratelimiting' | head -n 3
NAME                                                  STATUS   ROLES    AGE     VERSION
gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-l90m   Ready    <none>   3d17h   v1.21.11-gke.900
gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh   Ready    <none>   3d17h   v1.21.11-gke.900
```


SSH into node:

```
➜  ~ gcloud --project gitlab-pre compute ssh gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc
```

Once on the node, install and run `perf_flamegraph_for_all_running_processes.sh`:

```
igor@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ wget https://gitlab.com/gitlab-com/runbooks/-/raw/master/scripts/gke/perf_flamegraph_for_all_running_processes.sh

igor@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ bash perf_flamegraph_for_all_running_processes.sh

...

Starting capture for 60 seconds.
[ perf record: Woken up 33 times to write data ]
[ perf record: Captured and wrote 9.275 MB perf.data (47520 samples) ]
Please do not use --share-system anymore, use $SYSTEMD_NSPAWN_SHARE_* instead.
Spawning container igor-gcr.io_google-containers_toolbox-20201104-00 on /var/lib/toolbox/igor-gcr.io_google-containers_toolbox-20201104-00.
Press ^] three times within 1s to kill container.
Container igor-gcr.io_google-containers_toolbox-20201104-00 exited successfully.

Results:
Flamegraph:       /tmp/perf-record-results.6VUGMYa4/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc.20220331_144401_UTC.all_cpus.flamegraph.svg
Raw stack traces: /tmp/perf-record-results.6VUGMYa4/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc.20220331_144401_UTC.all_cpus.perf-script.txt.gz
```

Now you can scp the flamegraph to your local machine:

```
➜  ~ gcloud --project gitlab-pre compute scp gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc:/tmp/perf-record-results.6VUGMYa4/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc.20220331_144401_UTC.all_cpus.flamegraph.svg .
```

#### Profiling a specific container

Similar to the above, you can profile a single container rather than the whole host.

Find and ssh into a GKE node:

```
$ gcloud --project gitlab-pre compute instances list --filter 'name:gke-pre-gitlab-gke-redis'
$ gcloud compute ssh --project gitlab-pre --zone us-east1-b gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc
```

On the GKE node, fetch the helper script:

```
$ git clone git@gitlab.com:gitlab-com/runbooks.git
$ cd runbooks/scripts/gke/
```

Choose your target PID, and run the profiler on just its container:

```
$ TARGET_PID=$( pgrep -n -f 'redis-server .*:6379' )
$ bash ./perf_flamegraph_for_container_of_pid.sh $TARGET_PID
```

On your laptop, download the flamegraph (and optionally the perf-script output for fine-grained analysis):

```
$ gcloud compute scp --project gitlab-pre --zone us-east1-b gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc:/tmp/perf-record-results.oI3YR698/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc.20220414_010939_UTC.container_of_pid_7154.flamegraph.svg .

$ gcloud compute scp --project gitlab-pre --zone us-east1-b gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc:/tmp/perf-record-results.oI3YR698/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc.20220414_010939_UTC.container_of_pid_7154.perf-script.txt.gz .
```

## Finding relationships between processes, containers, and pods

After SSHing to a GKE node, you can use `crictl` to view containers and pods running on that node.

To find which container or pod owns a process, you can use the utilities in the runbooks repo's `scripts/gke` directory,
as shown below.

This is all run from outside the target container, in the GKE node's root process namespace.

Choose a process to inspect.

Note: This is the process's PID from the host's root namespace, not its PID from within the container's namespace.

```
msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ TARGET_PID=$( pgrep -f 'redis-server.*:6379' )

msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ ps uwf $TARGET_PID
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
chronos+    7154  1.5  0.0 139808 10200 ?        Ssl  Mar15 720:01 redis-server *:6379
```

Find the process's container id, and use `crictl` to display the container's summary info:

```
msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ crictl ps --id $( bash container_id_for_pid.sh "$TARGET_PID" )
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID
89e7d6da5f404       be0431d8c1328       4 weeks ago         Running             redis               0                   bb2d2ec8e1499
```

Find the process's pod id, and use `crictl` to display all containers in that pod:

```
msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-mabc ~ $ crictl ps --pod $( bash pod_id_for_pid.sh "$TARGET_PID" )
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID
f70ffec5e32e7       2600417bb7548       4 weeks ago         Running             metrics             0                   bb2d2ec8e1499
ad8d09b753bd6       de6f7fadcaf3d       4 weeks ago         Running             sentinel            0                   bb2d2ec8e1499
89e7d6da5f404       be0431d8c1328       4 weeks ago         Running             redis               0                   bb2d2ec8e1499
```

## Quick reference: Explore pods, containers, and images using `crictl`

All GKE nodes have the `crictl` utility installed by default.

This tool queries the container runtime (in this case runc/containerd) to expose details of the running pods and containers.

The following quick reference covers some common uses:

```
# List containers.
$ crictl ps

# List the containers of a given pod id (short or long id format).
$ crictl ps --pod $POD_ID

# List pods.
$ crictl pods

# List pods in namespace "redis".
$ crictl pods --namespace redis

# List pods having a specific label.
$ crictl pods --label 'app.kubernetes.io/instance=redis-ratelimiting'

# Pick an example pod or container id for use in subsequent commands.
$ POD_ID=$( crictl pods --latest --quiet --namespace redis )
$ CONTAINER_ID=$( crictl ps --latest --quiet --name sentinel )

# Inspect the details of a pod, container, or image.  JSON by default.
$ crictl inspectp $POD_ID
$ crictl inspect $CONTAINER_ID
$ crictl inspecti $IMAGE_ID

# Execute a command in a container.
$ crictl exec -it $CONTAINER_ID ps -ef
$ crictl exec -it $CONTAINER_ID which redis-cli

# Review available subcommands and arguments.
$ crictl --help
$ crictl ps --help
```

## Packet captures on a GKE node

Capturing a small sample of network traffic can be diagnostically useful.

The following helper scripts facilitate this:

```
tcpdump_on_gke_node.sh [max_duration_seconds] [tcpdump_options]
tcpdump_on_gke_node_for_pod_id.using_pod_iface.sh [pod_id] [max_duration_seconds] [tcpdump_options]
tcpdump_on_gke_node_for_pod_id.using_pod_netns.sh [pod_id] [max_duration_seconds] [tcpdump_options]
```

GKE nodes do not have `tcpdump` installed by default.  These scripts install it via toolbox,
choose a network interface to capture, run `tcpdump` with whatever additional options you specify,
and write the resulting compressed capture file to `/var/pcap/`.  From there, you can download
the pcap file for analysis.

### Quick reference: Packet capture commands

All of the following commands are run on a GKE node, outside of any container.

```
# Fetch the tools.
$ git clone https://gitlab.com/gitlab-com/runbooks.git
$ cd runbooks/scripts/gke/

# Capture all traffic on the host for up to 30 seconds or 10K packets, whichever comes first.
$ bash ./tcpdump_on_gke_node.sh 30 -c 10000

# Capture 10 seconds of traffic on the host for port 6379, regardless of pod.
$ bash ./tcpdump_on_gke_node.sh 10 'port 6379'

# Choose a pod to capture.
$ crictl pods
$ POD_ID=$( crictl pods --latest --quiet --namespace redis )

# Show the pod IP address.
$ bash ./ip_addr_for_pod_id.sh $POD_ID

# Capture 10 seconds of traffic to a single pod.  Includes loopback traffic between local containers.
$ bash ./tcpdump_on_gke_node_for_pod_id.using_pod_netns.sh "$POD_ID" 10

# Same as above, but excludes loopback traffic.
$ bash ./tcpdump_on_gke_node_for_pod_id.using_pod_iface.sh "$POD_ID" 10

# Capture 10 seconds of traffic to a single pod.
# Save space by capturing only incoming requests (not response data) on port 6379.
$ bash ./tcpdump_on_gke_node_for_pod_id.using_pod_netns.sh "$POD_ID" 10 'dst port 6379'
```

### Gotchas

Before running large or long-running packet captures, be aware of the following gotchas:
* Disk space:
  * The pcap files are saved to `/var/pcap` on the GKE host.
  * This is a disk-backed filesystem, so writing there is safer than writing to a `tmpfs` filesystem (i.e. does not consume memory).
  * However, its space is limited.  The same single filesystem holds container images and logs.  So be frugal.
  * If you generate a large pcap file, delete it when done.
* Cannot Ctrl-C a running capture:
  * Because we must run `tcpdump` inside the `toolbox` container, we cannot interactively interrupt the capture by pressing Ctrl-C.
  * Choose a reasonable max duration when running the tcpdump wrapper scripts.  Optionally also specify a max packet count (`-c 10000`).
  * If you need to quickly kill a capture, start a new shell on the GKE node and kill the `tcpdump` process:
    ```
    $ sudo pkill tcpdump
    ```

### Clone the tools onto your target GKE node

Find and ssh into a GKE node:

```
$ gcloud --project gitlab-pre compute instances list --filter 'name:gke-pre-gitlab-gke-redis'
$ gcloud compute ssh --project gitlab-pre gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh
```

On the GKE node, fetch the helper script:

```
$ git clone https://gitlab.com/gitlab-com/runbooks.git
$ cd runbooks/scripts/gke/
```

### Capturing traffic at the host or pod level

Note: Treat packet captures as potentially sensitive data.

Typically each pod runs in its own network namespace.
Multiple pods may have processes listening on the same port.

To capture traffic on that port for all pods, capture at the host level.
The following example captures for 10 seconds all traffic on port 6379
in both directions for all pods.

```
$ bash ./tcpdump_on_gke_node.sh 10 'port 6379'
```

To do the same capture for a specific single pod, choose a pod id, and run:

```
$ POD_ID=$( crictl pods --latest --quiet --namespace redis )
$ bash ./tcpdump_on_gke_node_for_pod_id.using_pod_netns.sh "$POD_ID" 10 'port 6379'
```

For reference during analysis, it is often helpful to know the pod's IP address:

```
$ bash ./ip_addr_for_pod_id.sh $POD_ID
10.235.8.8
```

When the capture finishes, it will show the full path to the output pcap file.

On your laptop, download the file using `gcloud compute scp`:

```
$ gcloud compute scp --project gitlab-pre gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh:/var/pcap/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz  /tmp/
No zone specified. Using zone [us-east1-b] for instance: [gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh].
External IP address was not found; defaulting to using IAP tunneling.
gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa79 100%   23KB 152.1KB/s   00:00    
```

### Demo

#### Capture

Choose a GKE host that is running a pod we want to observe.
Here we use `kubectl get pods` to find a node that is currently running a redis pod.

```
msmiley@saoirse:~$ kubectl get pods -n redis -o wide | grep 'redis'
redis-ratelimiting-node-0   4/4     Running   2          30h   10.235.8.8   gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh   <none>           <none>
```

SSH to the GKE node.

```
msmiley@saoirse:~$ gcloud compute ssh --project gitlab-pre gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh
```

Choose a pod.

```
msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh ~/runbooks/scripts/gke $ POD_ID=$( crictl pods --latest --quiet --namespace redis )

msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh ~/runbooks/scripts/gke $ echo $POD_ID
7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6

msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh ~/runbooks/scripts/gke $ crictl ps --pod $POD_ID
CONTAINER           IMAGE               CREATED             STATE               NAME                ATTEMPT             POD ID
f090b746ef29c       9319ef6fd72b0       31 hours ago        Running             sentinel            2                   7373dfce7087b
35c62fcef2873       6847317f2c777       31 hours ago        Running             process-exporter    0                   7373dfce7087b
f2927ce7eafd3       a9ef660d48b40       31 hours ago        Running             metrics             0                   7373dfce7087b
8ad5f5213991b       c7504ce63cbcb       31 hours ago        Running             redis               0                   7373dfce7087b
```

Run the capture.

```
msmiley@gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh ~/runbooks/scripts/gke $ bash ./tcpdump_on_gke_node_for_pod_id.using_pod_netns.sh "$POD_ID" 10 'port 6379'
Setting up toolbox.  (May take up to a minute during first run.)
tcpdump is already the newest version (4.9.3-1~deb10u1).
0 upgraded, 0 newly installed, 0 to remove and 1 not upgraded.
jq is already the newest version (1.5+dfsg-2+b1).
0 upgraded, 0 newly installed, 0 to remove and 1 not upgraded.

Capturing to pcap file: gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap
Please do not use --share-system anymore, use $SYSTEMD_NSPAWN_SHARE_* instead.
Spawning container msmiley-gcr.io_google-containers_toolbox-20201104-00 on /var/lib/toolbox/msmiley-gcr.io_google-containers_toolbox-20201104-00.
Press ^] three times within 1s to kill container.
tcpdump: listening on any, link-type LINUX_SLL (Linux cooked), capture size 262144 bytes
644 packets captured
847 packets received by filter
0 packets dropped by kernel
Container msmiley-gcr.io_google-containers_toolbox-20201104-00 exited successfully.
Compressing pcap file.
/media/root/var/pcap/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap:	 81.5% -- replaced with /media/root/var/pcap/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz
Results:
-rw-r--r-- 1 root root 23K May 20 22:45 /var/pcap/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz
```

Download the pcap file for analysis.

```
msmiley@saoirse:~$ gcloud compute scp --project gitlab-pre gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh:/var/pcap/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz  /tmp/
No zone specified. Using zone [us-east1-b] for instance: [gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh].
External IP address was not found; defaulting to using IAP tunneling.
gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa79 100%   23KB 152.1KB/s   00:00
```

#### Analysis

Analyze the pcap as you normally would.  Example:

```
$ PCAP_FILE=/tmp/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz

$ export TZ=UTC

$ capinfos -aceuxs $PCAP_FILE
File name:           /tmp/gke-pre-gitlab-gke-redis-ratelimiting-231e75c5-rpfh.pod_7373dfce7087b83d7d9040dd3149a3a81ff14c946f572aa7949a39a694eb69b6.20220520_224447.pcap.gz
Number of packets:   644
File size:           23 kB
Capture duration:    8.550298 seconds
First packet time:   2022-05-20 22:44:50.497803
Last packet time:    2022-05-20 22:44:59.048101
Average packet rate: 75 packets/s

$ tshark -r $PCAP_FILE -q -z conv,ip
================================================================================
IPv4 Conversations
Filter:<No Filter>
                                               |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                               | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
10.232.4.103         <-> 10.235.8.8               105 19 kB         105 21 kB         210 40 kB         0.114044000         8.3809
10.232.4.101         <-> 10.235.8.8                92 7,999 bytes      79 20 kB         171 28 kB         0.000000000         8.5503
10.235.8.8           <-> 10.232.4.102              49 16 kB          62 5,581 bytes     111 22 kB         0.138301000         8.3566
10.235.8.8           <-> 10.235.8.8                 0 0 bytes        96 18 kB          96 18 kB         0.138327000         8.3566
127.0.0.1            <-> 127.0.0.1                  0 0 bytes        56 4,204 bytes      56 4,204 bytes     0.463964000         5.0367
================================================================================

$ tshark -r $PCAP_FILE -q -z conv,tcp | head
================================================================================
TCP Conversations
Filter:<No Filter>
                                                           |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                                           | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
10.232.4.101:6379          <-> 10.235.8.8:37806                48 3,642 bytes      48 9,609 bytes      96 13 kB         0.000000000         8.4949
10.232.4.102:6379          <-> 10.235.8.8:49648                36 2,448 bytes      36 10 kB          72 13 kB         0.143919000         8.3510
10.232.4.103:6379          <-> 10.235.8.8:38996                36 2,448 bytes      36 10 kB          72 13 kB         0.143965000         8.3510
10.235.8.8:6379            <-> 10.235.8.8:52978                27 1,836 bytes      27 8,230 bytes      54 10 kB         0.143990000         8.3509
10.235.8.8:6379            <-> 10.232.4.103:43333              27 1,836 bytes      27 8,230 bytes      54 10 kB         0.144002000         8.3510

$ tshark -r $PCAP_FILE -T fields -e tcp.flags.str | sort | uniq -c
    284 ·······A····
      8 ·······A···F
    344 ·······AP···
      4 ·······A··S·
      4 ··········S·

$ tshark -r $PCAP_FILE -Y 'tcp.flags.syn == 1' -T fields -e frame.time -e tcp.flags.str -e ip.src -e ip.dst -e tcp.srcport -e tcp.dstport | head -n4
May 20, 2022 22:44:50.961767000 UTC	··········S·	127.0.0.1	127.0.0.1	39114	6379
May 20, 2022 22:44:50.961774000 UTC	·······A··S·	127.0.0.1	127.0.0.1	6379	39114
May 20, 2022 22:44:50.994887000 UTC	··········S·	127.0.0.1	127.0.0.1	39116	6379
May 20, 2022 22:44:50.994896000 UTC	·······A··S·	127.0.0.1	127.0.0.1	6379	39116

$ wireshark -r $PCAP_FILE -Y 'ip.addr == 127.0.0.1 && tcp.port == 39114 && tcp.port == 6379'
```
