# Querying Thanos via Google Functions and Prometheus API

### Overview
Currently, there are couple of ways to retrieve Prometheus metrics. 

1. Directly browse to `https://thanos-query.ops.gitlab.net/graph` and enter an expression.
2. By leveraging Prometheus API, pull the desired metrics by calling Prometheus API i.e `https://thanos-query.ops.gitlab.net/api/v1/query?query=` and provide the query string. 

This documentation provides information on a third way of pulling Prometheus metrics -- which can be done in an automated way. A need for this came up initially in: https://gitlab.com/gitlab-data/analytics/issues/2827. One of the considerations we had for automation was to set it up within our GCP instead of setting it up within our dev machines. 

### Setup
Our resources behind `https://thanos-query.ops.gitlab.net` are protected behind IAP (Identity-Aware Proxy) so requests are verified based on their identities before being allowed to be processed. Instead of putting the automation work on our dev machines, we deployed it to Google Functions and protected the function so that only authenticated users can invoke it. And for the function to be able to access and call HTTP endpoints on the IAP protected resources, we setup a service account and allowed it to access them. The below are the components of the setup:

#### GCP Project
- `gitlab-ops`
- Link: https://console.cloud.google.com/home?project=gitlab-ops

#### Service Account
- `infra-kpi`
- Link: https://console.cloud.google.com/iam-admin/serviceaccounts/details/117763940116096665798?project=gitlab-ops

#### HTTPS Resource
- `ops-thanos-query`
- Link: https://console.cloud.google.com/security/iap?project=gitlab-ops

#### Google Function
- `query-thanos-infra-kpi`
- It is a protected Google Function which requires a user/client provide a valid token. (We didn't want it to be accessible by anyone on public internet)
- Resource Link: https://console.cloud.google.com/functions/details/us-central1/query-thanos-infra-kpi?project=gitlab-ops
- Trigger Endpoint: https://us-central1-gitlab-ops.cloudfunctions.net/query-thanos-infra-kpi 
- Parameter: `query`. Provide a query string (i.e `up&start=2019-11-20T20:10:30.781Z&end=2019-11-20T20:10:31.781Z&step=15s`)

### Instruction
The `query-thanos-infra-kpi` is written in Python and queries `https://thanos-query.ops.gitlab.net`. It takes care of the authentication work behind the scene. All we need to do is invoke the Google Function and provide a `query` string which one would typically provide in one of the before-mentioned two ways. Steps to invoke `query-thanos-infra-kpi`:

1. Login to GCP and change to [`gitlab-ops` project](https://console.cloud.google.com/home/dashboard?authuser=0&project=gitlab-ops).
2. Activate Cloud Shell 
3. Once the cloud shell is activated, make sure `gitlab-ops` is selected. 
4. Run: `gcloud auth print-identity-token` and copy the token. (This will be needed to invoke the Google Cloud function)
5. Then run `curl` against the `query-thanos-infra-kpi` trigger endpoint and provide a `query` parameter on what it is that you would like to run. Example: 

```
curl -X POST "https://us-central1-gitlab-ops.cloudfunctions.net/query-thanos-infra-kpi" -H "Authorization: bearer {TOKEN_COPIED_FROM_GCLOUD_SHELL}" -d '{"query": "up&start=2019-11-20T20:10:30.781Z&end=2019-11-20T20:10:31.781Z&step=15s"}' -H "Content-Type: application/json"
```

### Next Steps
From here on, you can leverage the Google Function capability and do more fascinating automations such as:
1. Run on-demand scripts from your local machine
2. Setup a Google Cloud Scheduler job and let it trigger the `query-thanos-infra-kpi` function on certain intervals. 






