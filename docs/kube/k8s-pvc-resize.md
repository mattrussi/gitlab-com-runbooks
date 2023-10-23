# How to resize Persistent Volumes in Kubernetes

Suppose you have some Persistent Volumes attached to Pods from a Controller
(StatefulSet/Deployment/DaemonSet) and you need to increase their size because
it is getting full. Kubernetes supports volume expansion by default (>=
Kubernetes 1.24).

This feature allows Kubernetes users to simply edit their PersistentVolumeClaim
objects and specify new size in PVC Spec and Kubernetes will automatically
expand the volume using storage backend and also expand the underlying file
system in-use by the Pod without requiring any downtime at all if possible.

You can only resize volumes containing a file system if the file system is XFS,
Ext3, or Ext4.

Additional read:

- [Kubernetes docs](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims)
- [Feature announce](https://kubernetes.io/blog/2022/05/05/volume-expansion-ga/)

## Procedure

As an example here, we will be resizing the Persistent Volumes for the
Deployment `receive-gitlab-thanos-compactor` from 10GiB to 20GiB.

### Step 1: Preflight checks

- [ ] Verify storage class supports volume expansion `kubectl get storageclass`
- [ ] Make sure your PVC size changes in Helm/Tanka/other are ready to merge
      and deploy (but don't merge yet!)
- [ ] Confirm you have access to the targeted Kubernetes cluster as [described
      in the runbook](https://ops.gitlab.net/gitlab-com/runbooks/-/blob/master/docs/kube/k8s-oncall-setup.md#accessing-clusters-via-console-servers)

### Step 2: Check the current state

Check that the current Persistent Volume Claim in the targeted resource matches
its original definition, and than the existing Persistent Volumes are really
those you are targeting and that their original size also matches:

```
$ kubectl -n thanos describe Deployment/receive-gitlab-thanos-compactor
Name:               receive-gitlab-thanos-compactor
Namespace:          thanos
CreationTimestamp:  Wed, 04 Oct 2023 05:50:04 +0100
Labels:             app.kubernetes.io/component=compactor
                    app.kubernetes.io/instance=receive-gitlab
                    app.kubernetes.io/managed-by=Helm
                    app.kubernetes.io/name=thanos
                    helm.sh/chart=thanos-12.11.0
...
  Volumes:
   objstore-config:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  receive-gitlab-thanos-objstore-secret
    Optional:    false
   data:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  receive-gitlab-thanos-compactor
    ReadOnly:   false
...
Events:          <none>

$ kubectl -n thanos get pvc receive-gitlab-thanos-compactor

NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE    VOLUMEMODE
receive-gitlab-thanos-compactor    Bound    pvc-897d200e-b8af-4fd0-a5ac-a7142b2662b9   20Gi       RWO            pd-balanced    16d    Filesystem
```

Nothing unexpected? Great, let's proceed!

### Step 3: Merge your Merge Request

After the pipeline ran, you can check if the PVC has been resized. A few minutes
later the file system is resized online by Kubernetes.

```
$ kubectl -n thanos get pvc -l app.kubernetes.io/component=compactor -o wide

NAME                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE    VOLUMEMODE
receive-default-thanos-compactor   Bound    pvc-d4590947-3b34-4d59-9f36-44ff6bc1a11b   10Gi       RWO            pd-balanced    48d    Filesystem
receive-gitlab-thanos-compactor    Bound    pvc-897d200e-b8af-4fd0-a5ac-a7142b2662b9   100Gi      RWO            pd-balanced    19d    Filesystem
receive-ruler-thanos-compactor     Bound    pvc-9847345f-493e-4c90-81f1-918313169004   10Gi       RWO            pd-balanced    48d    Filesystem
```

If alerts were firing due to reaching the saturation threshold, confirm that
they aren't firing any longer.

If everything is looking good, you're finished!

## Rollback

Please be aware that it is not possible to shrink a PVC. Any new Spec whose size
reverts the PVC to its previous size (is less than the current one) will be
rejected by the Kubernetes API.
