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

### Kafka

#### `OFFSET_OUT_OF_RANGE` Broker: Offset out of range

Surfaced as log messages like these in the affected consumer pods, which will also be crashlooping:

```
arroyo.errors.OffsetOutOfRange: KafkaError{code=_AUTO_OFFSET_RESET,val=-140,str="fetch failed due to requested offset not available on the broker: Broker: Offset out of range (broker 2)"}
```

This means Kafka has gone out of sync with the consumers. According to the [official docs](https://develop.sentry.dev/self-hosted/troubleshooting/#kafka), there are a number of reasons for this, but we've only previously run into this due to memory pressure.

**The resolution _does_ result in data loss!** However it can't be helped if the cluster isn't processing anything due to this error.

1. Take note of what's failing. For example, if the pods in deployment `sentry-ingest-consumer-events` are crashlooping with the above log message, we know the relevant queue in Kafka would have something to do with the `events` `ingest-consumer`.
1. Scale down the problem deployment to 0.
1. Bring up a shell on one of the Kafka pods - doesn't matter which, in this example we'll just use `kafka-0`.
1. Check the status of the problematic consumer group (in this example, `ingest-consumer` is our consumer group).

    ```
    I have no name!@sentry-kafka-0:/$ JMX_PORT="" /opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group ingest-consumer -describe

    GROUP           TOPIC               PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
    ingest-consumer ingest-attachments  0          -               0               -               rdkafka-18ac30b0-09db-40e5-b3f9-cf9e77bece92 /10.252.36.95   rdkafka
    ingest-consumer ingest-transactions 0          32204576        32204580        4               rdkafka-9020993b-f5f7-4b9e-8cd5-f7047f7a0672 /10.252.33.200  rdkafka
    ingest-consumer ingest-events       0          144444096       150079891       5635795         -                                            -               -

    ```

    The output above means that the `ingest-events` topic currently has no consumers (since we scaled down the deployment to 0) and it's very behind (large lag value).
1. In order to properly recover, we also need to ensure there are no consumers active for the other topics in the consumer group. In this example we need to scale down the deployments for `sentry-ingest-consumer-attachments` and `sentry-ingest-consumer-transactions` to 0. Check that you've done this properly by rerunning the command to describe the consumer group above - `CONSUMER-ID` and `HOST` should be empty for the `ingest-attachments` and `ingest-transactions` topics afterward.
    * Failing to do this will result in a log message like `Error: Assignments can only be reset if the group 'ingest-consumer' is inactive, but the current state is Stable.` when you try and do the reset.
1. Now we have to reset the offset of the problematic topic.
    1. Do a dry run to check what the new offset will be: `JMX_PORT="" /opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group ingest-consumer --topic ingest-events --reset-offsets --to-latest --dry-run`
    1. If the new offset looks acceptable, execute the reset: `JMX_PORT="" /opt/bitnami/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group ingest-consumer --topic ingest-events --reset-offsets --to-latest --execute`. The output should look something like:

    ```
    GROUP                          TOPIC                          PARTITION  NEW-OFFSET
    ingest-consumer                ingest-events                  0          150082383
    ```

1. Scale the deployments you scaled down before back up. They should no longer be stuck printing errors.

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
