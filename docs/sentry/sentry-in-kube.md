# Managing Sentry in Kubernetes

The following runbooks only applies to the instance of Sentry running in the `ops` GKE cluster (running Sentry 22.9.0+). They are **not applicable** to the old instance of Sentry running on a single VM (version 9.1.2).

## Upgrading Sentry

**You should only attempt upgrades when the [Sentry chart](https://github.com/sentry-kubernetes/charts) gets bumped. Some upgrades bring architectural changes which the chart should handle for us.**

### Minor upgrade

Minor upgrades should not require database migrations, and incur little to no downtime.

1. Open an MR bumping the chart version [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/bases/environments.yaml#L165-168).
1. Review the release diff to look out for any potential breaking changes/downtime.
1. Merge the MR and get it applied in `ops`.
1. Helm will update the manifests and wait for pods to rotate.
    * If the pods fail to rotate, look into the deployment pods and check the pod events for any errors, errors could come from the application itself, so check pod logs too.
    Application errors will usually crop up in the `sentry-web` or `sentry-worker` pods.
    * You can also restart the pods yourself by running `kubectl rollout restart deployment/sentry-web` or `kubectl rollout restart deployment/sentry-worker`.
1. Double check that:
    * The Sentry UI shows the new version number (in the footer)
    * Running `sentry --version` in a shell on the web/worker pods should also return the new version number

### Major upgrade

Major upgrades usually involve database migrations.

1. Before opening any MRs, we need to ensure that the Postgres user Sentry uses for database access is granted superuser access.
    1. Forward port 5432 on the Cloud SQL proxy pod in the Sentry namespace to your local machine port 5432. The pod will usually be called something like `sentry-sql-proxy-gcloud-sqlproxy-...`
    1. Access the database via `psql` as the `postgres` user: `psql -U postgres -d sentry` (password can be found in 1Password under _Ops Sentry Cloud SQL instance_)
    1. Grant `cloudsqlsuperuser` role access to the service account used by Sentry for DB access: `grant cloudsqlsuperuser to "sentry-k8s-sa@gitlab-ops.iam";`
    1. Exit.
1. Open an MR bumping the chart version [here](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/blob/master/bases/environments.yaml#L165-168).
1. Merge the MR and get it applied in `ops`.
1. Helm will update the manifests and wait for pods to rotate.
    * If the pods fail to rotate, look into the deployment pods and check the pod events for any errors, errors could come from the application itself, so check pod logs too.
    Application errors will usually crop up in the `sentry-web` or `sentry-worker` pods.
    * You can also restart the pods yourself by running `kubectl rollout restart deployment/sentry-web` or `kubectl rollout restart deployment/sentry-worker`
    * If the hooks aren't run (or don't finish), you'll need to run the migrations yourself:
      1. On one of the worker pods (which should already be running the new version of Sentry), bring up a shell and run `sentry upgrade`.
      1. On one of the `snuba-api` pods, run `snuba migrations migrate`.
    * You'll know if migrations failed to run if you see errors in the Sentry UI complaining about version mismatches.
1. Revoke superuser access in the DB from the service account. Follow the same instructions above to login and access the DB as the `postgres` user, then run `revoke cloudsqlsuperuser from "sentry-k8s-sa@gitlab-ops.iam";`
1. Double check that:
    * The Sentry UI shows the new version number (in the footer)
    * Running `sentry --version` in a shell on the web/worker pods should also return the new version number

## Application errors

### RabbitMQ

RabbitMQ problems manifest themselves as AMQP error logs in the worker pods. For example, these errors started showing up after a borked update:

```
amqp.exceptions.PreconditionFailed: Queue.declare: (406) PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'counters-0' in vhost '/': received 'false' but current is 'true'
00:54:37 [CRITICAL] celery.worker: Unrecoverable error: PreconditionFailed(406, "PRECONDITION_FAILED - inequivalent arg 'durable' for queue 'counters-0' in vhost '/': received 'false' but current is 'true'", (50, 10), 'Queue.declare')
```

Unfortunately the only way I could resolve this was to forcibly reset the RabbitMQ nodes, wiping the existing queues, so this should only be done as a **last resort!**

1. Bring up a shell on any RabbitMQ pod. [RabbitMQ clusters don't have leaders](https://www.rabbitmq.com/clustering.html#peer-equality) like in other systems so you can theoretically run the following commmands on any pod you like, as long as it's part of the RabbitMQ cluster.
1. Stop the RabbitMQ app running on all pods in the cluster.
    * If I'm on the 3rd pod in a 3-pod cluster, the commands I need to run will look like this:

      ```
      rabbitmqctl -n rabbit@sentry-rabbitmq-1.sentry-rabbitmq-headless.sentry.svc.cluster.local stop_app

      rabbitmqctl -n rabbit@sentry-rabbitmq-2.sentry-rabbitmq-headless.sentry.svc.cluster.local stop_app

      rabbitmqctl stop_app
      ```

1. [Force reset](https://www.rabbitmq.com/rabbitmqctl.8.html#force_reset) all pods in the cluster.
    * In a similar 3-pod setup to above, I'd run:

      ```
      rabbitmqctl -n rabbit@sentry-rabbitmq-1.sentry-rabbitmq-headless.sentry.svc.cluster.local force_reset

      rabbitmqctl -n rabbit@sentry-rabbitmq-2.sentry-rabbitmq-headless.sentry.svc.cluster.local force_reset

      rabbitmqctl force_reset
      ```

1. Restart all the pods in the cluster. They should discover each other automatically.
    * In a similar 3-pod setup to the above, I'd run:

      ```
      rabbitmqctl start_app

      rabbitmqctl -n rabbit@sentry-rabbitmq-1.sentry-rabbitmq-headless.sentry.svc.cluster.local start_app

      rabbitmqctl -n rabbit@sentry-rabbitmq-2.sentry-rabbitmq-headless.sentry.svc.cluster.local start_app
      ```

1. Check that the cluster is back to normal by running `rabbitmqctl cluster_status`
