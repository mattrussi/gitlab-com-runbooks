# How to resize Persistent Volumes in Kubernetes

Suppose you have some Persistent Volumes attached to Pods from a StatefulSet
and you need to increase their size because it is getting full. Unfortunately
[Kubernetes is currently unable to apply this change without recreating the
StatefulSet](https://github.com/kubernetes/kubernetes/issues/68737) so you will
need to do some additional manual work to carry it. This runbook will guide you
through the necessary steps to do so safely and without downtime.

You can find a real life application of this procedure
[here](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5239), which
we will use as an example in this runbook.

## Procedure

As an example here, we will be resizing the Persistent Volumes for the
StatefulFul sets `thanos-store-0` from 5GiB to 20GiB.

### Step 1: Preflight checks

- [ ] Make sure your PVC size changes in Helm/Tanka/other are ready to merge
      and deploy (but don't merge yet!)
- [ ] Confirm you have access to the targeted Kubernetes cluster as [described
      in the runbook](https://ops.gitlab.net/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-oncall-setup.md#accessing-clusters-via-console-servers)

### Step 2: Check the current state

Check that the current Persistent Volume Claim in the targeted StateFul Set
matches its original definition, and than the existing Persistent Volumes are
really those you are targeting and that their original size also matches:
```
$ kubectl -n monitoring describe sts/thanos-store-0
Name:               thanos-store-0
Namespace:          monitoring
[...]
Volume Claims:
  Name:          data
  StorageClass:  ssd
  Labels:        app.kubernetes.io/component=object-store-gateway
                 app.kubernetes.io/instance=thanos-store-0
                 app.kubernetes.io/name=thanos-store
                 store.observatorium.io/shard=shard-0
  Annotations:   <none>
  Capacity:      5Gi
  Access Modes:  [ReadWriteOnce]
Events:          <none>

$ kubectl -n monitoring get pvc -l app.kubernetes.io/name=thanos-store -o wide
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE    VOLUMEMODE
data-thanos-store-0-0   Bound    pvc-c013133d-91d1-4a4c-9289-895a7792aa61   5Gi        RWO            ssd            250d   Filesystem
data-thanos-store-0-1   Bound    pvc-9d8cc41f-cfb5-4828-ad55-3e703337c6e2   5Gi        RWO            ssd            250d   Filesystem
```

Nothing unexpected? Great, let's proceed!

### Step 3: Delete the StateFul Set

Delete the StatefulSet object without deleting the pods underneath:
```
kubectl -n monitoring delete --cascade=orphan sts/thanos-store-0
```

Confirm that the pods still exist:
```
kubectl -n monitoring get pod -l app.kubernetes.io/name=thanos-store
```

Our service is still up? Let's continue!

### Step 4: Resize the Persistent Volumes

Manually patch the Persistent Volume Claims to their new size:
```
kubectl -n monitoring patch pvc/data-thanos-store-0-0 -p '{ "spec": { "resources": { "requests": { "storage": "20Gi" }}}}'
kubectl -n monitoring patch pvc/data-thanos-store-0-1 -p '{ "spec": { "resources": { "requests": { "storage": "20Gi" }}}}'
```

Their status should show that the resize is pending, waiting for the attached pods to be restarted:
```
$ kubectl -n monitoring get pvc -l app.kubernetes.io/name=thanos-store -o yaml
apiVersion: v1
kind: PersistentVolumeClaim
[...]
spec:
  resources:
    requests:
      storage: 20Gi
[...]
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2021-08-02T12:34:56Z"
    message: Waiting for user to (re-)start a pod to finish file system resize of
      volume on node.
    status: "True"
    type: FileSystemResizePending
  phase: Bound
```

Now you can merge and deploy your changes normally, this should recreate the
StatefulSet with the new PVC size and it will recover its running pods without
recreating them.

At this point the Persistent Volumes are still at their original size and their
resize is still pending, so let's restart the attached pods one at a time to
arrange that:
```
kubectl -n monitoring delete pod/thanos-store-0-0
kubectl -n monitoring get pods -l app.kubernetes.io/name=thanos-store -o wide
# Wait for the pod to be running then proceed to the next one
kubectl -n monitoring delete pod/thanos-store-0-1
kubectl -n monitoring get pods -l app.kubernetes.io/name=thanos-store -o wide
```

Are the pods running? Awesome! The Persistent Volumes should now be resized, let's check that.

# Step 5: Post-operation checks

Check that the Persistent Volume Claims are showing the new size:
```
$ kubectl -n monitoring get pvc -l app.kubernetes.io/name=thanos-store -o wide
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE    VOLUMEMODE
data-thanos-store-0-0   Bound    pvc-c013133d-91d1-4a4c-9289-895a7792aa61   20Gi       RWO            ssd            250d   Filesystem
data-thanos-store-0-1   Bound    pvc-9d8cc41f-cfb5-4828-ad55-3e703337c6e2   20Gi       RWO            ssd            250d   Filesystem
```

You can also confirm inside a pod that new volume mount shows an increased size:
```
kubectl -n monitoring exec -it thanos-store-0-0 -- df -h /var/thanos/store
kubectl -n monitoring exec -it thanos-store-0-1 -- df -h /var/thanos/store
```

And finally, check that the Stateful Set exists:
```
kubectl -n monitoring get sts/thanos-store-0
```

If everything is looking good, you're finished!

## Rollback

In case something goes unexpectedly wrong and the resize fails, you can simply
revert the Stateful Set to its previous state.

If the StateFul Set exists, delete it with `--cascade=orphan`:
```
kubectl -n monitoring delete --cascade=orphan sts/thanos-store-0
```

Then create a revert MR for your changes and apply it.

And finally, confirm that the Stateful Set and its pods exist:
```
kubectl -n monitoring get sts/thanos-store-0
kubectl -n monitoring get pod -l app.kubernetes.io/name=thanos-store
```
