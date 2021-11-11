# Quotas

There is a limit of how many requests we can send to Google Cloud API.
There are different kind of quotas some API request specific and some
resource specific.

To read about this you can look at GCP quotas:

- [Resource quotas](https://cloud.google.com/compute/quotas)
- [API quota](https://cloud.google.com/docs/quota#api-specific_quota)
- [Increase quota](https://cloud.google.com/compute/quotas#requesting_additional_quota)

## Dashboard

There is a specific quota usage dashboard which can be found in:
<https://dashboards.gitlab.net/d/sXVh89Imk/ci-autoscaling-providers?viewPanel=8&orgId=1&var-gcp_exporter=shared-runners-manager-3.gitlab.com:9393&var-gcp_region=All>.
This doesn't cover the API quota because they aren't exported yet.

## Runner logs

You should be able to see if `gitlab-runner` is reaching the Quota limits
by searching in the `pubsub-runner-inf-gprd` index in
[Kibana](https://log.gprd.gitlab.net/goto/0c1056bfebe7f988bbbb6119a293c448).

![resource quota exceeded example](./img/quota_exceeded_resource.png)
![api quota exceeded example](./img/quota_exceeded_api.png)
![api quota exceeded example](./img/quota_exceeded_operation.png)
