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
