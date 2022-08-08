<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# Kas Service

* [Service Overview](https://dashboards.gitlab.net/d/kas/kas)
* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22kas%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service:kas"

## Logging

* [kas](https://log.gprd.gitlab.net/goto/b8204a41999cc1a136fa12c885ce8d22)

## Troubleshooting Pointers

* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [Kubernetes-Agent Basic Troubleshooting](kubernetes-agent-basic-troubleshooting.md)
* [Kubernetes-Agent Disable Integrations](kubernetes-agent-disable-integrations.md)
* [An impatient SRE's guide to deleting alerts](../monitoring/deleting-alerts.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Diagnosis with Kibana](../onboarding/kibana-diagnosis.md)
<!-- END_MARKER -->

# Summary

The GitLab Kubernetes Agent is an active in-cluster component for solving GitLab and Kubernetes integration tasks in a secure and cloud-native way. It enables:

* Integrating GitLab with a Kubernetes cluster behind a firewall or NAT (network address translation).
* Pull-based GitOps deployments by leveraging the GitOps Engine.
* Allows Gitlab Real-time access to the Kubernetes API endpoints in a users cluster
* Grants Gitlab the ability to build extra functionality on top of the pieces above, e.g. [Kubernetes network security alerts](https://docs.gitlab.com/ee/user/clusters/agent/#kubernetes-network-security-alerts)

More information can be found at <https://docs.gitlab.com/ee/user/clusters/agent/>

# Operations

## Controls

1. The internal API for `kas` can be disabled using a feature flag (`kubernetes_agent_internal_api`). This cuts off `kas` from GitLab.
When this flag is disabled, `kas` will see 404s when accessing the internal API.
There might be a delay when `kas` sees 404s depending on cache configurations.
The `agentk` clients will receive no indication that the flag is disabled.

NOTE: As this will cause `kas` to silently fail to connect to the Gitlab API, the end result for users will be that they will see their `agentk` clients fail to do anything silently, while the `kas` containers on our side will throw errors. This could become a cause for confusion for users, so we must ensure we only disable this in the most dire of circumstances, and communicate to users that agents will by non-functional while disabled.

Other configurations

# Architecture

```plantuml
top to bottom direction
skinparam sequenceMessageAlign left
skinparam roundcorner 20
skinparam shadowing false
skinparam rectangle {
  BorderColor DarkSlateGray
}

card "Gitlab User Kubernetes Cluster" as GUKC {

  rectangle "agentk Pod" as AGENTK {
  }

}

cloud "Internet" as INTERNET {

}

card "kas.gitlab.com GCP Load Balancer" as LB {
}

rectangle "GKE Regional Cluster" as GKE {
  card "gitlab namespace" as GPRD {
    rectangle "KAS Pod" as KAS
  }

}
rectangle "Virtual Machines" as VMS {
  rectangle "GitLab.com /api" as GLAPI
  rectangle "Gitaly" as GITALY
  rectangle "redis" as REDIS
}


AGENTK -- INTERNET
INTERNET --> LB
LB --> KAS
KAS --> GLAPI : Authn/Authz of agentk
KAS --> GITALY : Fetch data from git repo
KAS --> REDIS: Store/Read info about `agentk` connections
```

## Dependencies

1. GCP HTTPS Load Balancer, is used to load balance requests between the agentk (and the internet)  and kas.
1. GitLab Web (Rails) server, which serves the internal API for kas.
1. Gitaly, which provides repository blobs for the agent configuration, and K8s resources to be synced.
1. Redis, which is used to store

* Information about kas access tokens and IP addresses, to allow us to do rate limiting against kas per IP and token
* Tracking connected `agentk` agents to kas

## Ingress Architecture

The first layer in front of KAS is Cloudflare, but currently it is only used in raw tcp mode (not as a HTTPS proxy). This is done this way for simplicity around TLS setup (as we use Google managed certificates) and because KAS will migrate to GRPC, which needs additional testing with cloudflare (cloudflare GRPC support is in beta). It however is likely we will further change and evolve the cloudflare configuration in the future.

After cloudflare KAS uses it's own [GKE Ingress](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress), currently running in HTTP1.1 with websockets. This is instead of using haproxy, and is on an entirely separate domain at <https://kas.gitlab.co>. The reason for such isolation is because `kas` is focussed on long-lived connections (living indefinately, always trying to remain connected). We didn't want to have `kas` connections tying up the same ingress resources that the rest of Gitlab uses (haproxy, ingress-nginx, etc). On top of this, it simplifies the deployment stack and gives us access to a number of features we can leverage including

* [Google Managed Certificate](https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs) for <https://kas.gitlab.com>, deployed and managed by a Kubernetes CRD in the [gitlab-extras helm release](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-extras/values.yaml.gotmpl#L3-10)

* We configure the GKE Ingress (which is implemented by a GCP HTTPS Load Balancer) to use a custom HTTP healthcheck, as the readiness and liveness endpoints for `kas` live on a different port than the port used to serve traffic (due to the nature of websockets/grpc). It is also part of the [gitlab-extras helm release](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab-extras/values.yaml.gotmpl#L12-22)

* We also leverage [container native load balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/container-native-load-balancing) to allow the GCP Load Balancer to map endpoints and route traffic **directly to the pods via their individual pod IPs**. This bypasses the usual mechanism of mapping endpoints as nodes, requiring a service being exposed as a `NodePort`, and utilising `kube-proxy` to configure `iptables` rules to route traffic in an even matter. This overall provides a much simpler network topology, with less hops. A Kubernetes `service` object is still needed for GKE/GCP to sync the endpoint list to the HTTPS load balancer, but the `ClusterIP` (or indeed any IP) of the `service` object is not actually used.

* [Google Cloud Armor](https://cloud.google.com/armor) to basically firewall/restrict the KAS GKE Ingress from only being externally accessable by cloudflare

Looking at the settings on the `BackendConfig` object for the GKE ingress, as well as the [default settings for GCP Loadbalancers](https://cloud.google.com/load-balancing/docs/https) ( [see also](https://cloud.google.com/load-balancing/docs/https#timeouts_and_retries) ), we can determine the following current settings are set

* The loadbalancer will determine the health of a pod (which is directly a loadbalancer backend) by polling port 8181 with URI `/liveness` every 5 seconds, with a timeout of 3 seconds

* The current implmentation of the liveness check simply returns a HTTP 200 OK, so is only reliabile for basic determination of a pods health <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/observability/metric_server.go#L59-72>

* Between the load balancer and the backends (pods) there is a HTTP keepalive timeout of 600 seconds which cannot be adjusted.

* Between the load balancer and the backends (pods) there is a configurable timeout which we set quite high as the connections are websockets. We currently set that to 30 minutes and 30 seconds.

* The clients have been configured to have a graceful timeout of 30 minutes, after which they will close and re-open a connection <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/kascfg/config_example.yaml#L19>

* The clients have been configured to have a keep-alive ping of 55 seconds (just under 1 minute)

* Google documentation does not reveal any maximum connection limit for their Load Balancers, only that it's limited by the capacity of your backend service (I think suggesting they can probably scale them
much higher than we can scale our infra)

As kas is behind both cloudflare and a GCP HTTPS Loadbalancer, the pods should see the `X-Forwarded-For` Header with all relevant IP addresses regardless of network path. If set by cloudflare, GCP will gracefully append its own data to it as documented [here](https://cloud.google.com/load-balancing/docs/https#x-forwarded-for_header)

## Agent, KAS, and Rails Architecture

See <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md#high-level-architecture>

We have two components for the Kubernetes agent:

* The GitLab Kubernetes Agent Server (`kas`). This is deployed server-side together with the GitLab web (Rails), and Gitaly. It's responsible for:
  * Accepting requests from `agentk`.
  * [Authentication of requests](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/identity_and_auth.md) from `agentk` by querying `GitLab RoR`.
  * Fetching agent's configuration from a corresponding Git repository by querying `Gitaly`.
  * Polling manifest repositories for [GitOps support](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/gitops.md) by talking to `Gitaly`.
* The GitLab Kubernetes Agent (`agentk`). This is deployed to the user's Kubernetes cluster. It is responsible for:
  * Keeping a connection established to a `kas` instance
  * Processing GitOps requests from `kas`

# Performance

A rate limit on a per client basis can be configured with the `connections_per_token_per_minute` setting] - the default is 100 new connections per minute per agent. This requires Redis in order to track connections per agent. This rate limiting was introduced in <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/103>.

The frequency of gRPC calls from `kas` to `Gitaly` can be configured (see <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/pkg/kascfg/config_example.yaml>).

## Kas and redis

Each kas instance holds up to 5 connections to Redis. This is configurable. You can see other parameters there too - dial, read, write, idle timeouts. If there is no or limited activity, we may only have e.g. 1 open connection (depending on the idle timeout, which is 50 seconds by default). Number of requests per seconds and the overall amount of data depend on the number of connected agentk Pods.

### Redis requests due to rate limiting

#### Request/second estimation

It's 2 requests to Redis per 1 gRPC request to kas from each agentk Pod. Types of requests:

Configuration: Requests are long running. If there are no configuration updates (the usual situation - agent configuration should be pretty static), then the connection is closed and re-opened every 30 minutes. If there is an update then after it's sent to the agent, the connection is re-established (i.e. a request is made) and it sits there until the next update (or 30 minutes).

GitOps: Requests are long running. Works exactly the same as above with 1 gRPC request per configured manifest repository. If GitOps is not configured (i.e. 0 repos), no requests are made. Our expectation is that most users will use 1 manifest repository i.e. 1 gRPC request/30 minutes if no changes or 1 gRPC request per commit to that repository.

Reverse gRPC tunnel: Same model as above. Each agentk Pod establishes 10 gRPC tunnel connections to kas. They stay open for 30 minutes and are then re-established. Nothing uses them at the moment. This is for gitlab-org&5528 and other features in the future, in development that's why unused.

Cillium: 1 gRPC request per Cilium alert. How often - depends on the user's cluster and configuration of Cillium rules.

We expect a typical load of 11+ gRPC requests i.e. 22+ Redis requests per 30 minute interval + GitOps + Cillium requests per connected agentk Pod. That is ~0.03+ requests per second per connected agentk Pod (lower bound).
Rate limiter sets TTL for data to 59 seconds. "30 minutes" above, means 30 minutes with 5% jitter.

#### Size estimations

Rate limiter uses ~25 bytes per agent token (we store half the token in Redis, and a int count).

Redis requests due to tracking of connected agents

##### Request/second estimation

kas tracks connected agentk Pods in Redis for various purposes:

connectionsByAgentId - to look up information about connected agentk Pods by agent id.

connectionsByProjectId - same as above but by configuration project id.

tunnelsByAgentId - to look up information about connected reverse tunnels by agent id. Each agentk Pod establishes 10 tunnels.

All 3 use the same code for storage. Data is stored in a hash:

Key of the hash is constructed using the agent/project id.
key of the value inside of the hash is just a random 64 bit integer as a string
Value in the hash is a generic wrapper to track the expiration time (because Redis does not support TTL on key-value pairs inside of a hash) and the wrapped value holds the actual information.
Hash has a TTL on the whole hash set to 5 minutes. This is re-set every time a value is written to the hash and periodically (see below). If kas stops data will be eventually gone and that's the desired behavior.
Data inside of the hash is refreshed and GCed every 4 and 10 minutes. GC is needed so that instances of kas take care of stale data that another instance of kas wrote that then e.g. crashed is cleaned up. Refresh is needed so that data from kas instance A that is still needed is not GCed by kas instance B. Amount of data read and written and the number of requests to Redis depend on the number of things tracked i.e. number of connected agentk Pods. Reads use HSCAN for most efficient iteration and writes use pipelining for best network/connection utilization.

Per connected agentk Pod we expect a typical load of:

3+ Redis requests per 4 minute interval for refresh of 3 hashes above. This scales sublinearly because there are likely more than 1 agentk Pod per project/agent id so they are batched together on both the read and write paths.
3+ Redis requests per 10 minute interval for GC of hashes above. Same as above re. scaling.
We actually don't have any features that perform hash lookups at the moment. We are planning and working on: agent list page, agent info page, Kubernetes CI tunnel, etc. They will all access data in Redis.

That is ~0.012+ + ~0.005+ = ~0.017+ requests per second per connected agentk Pod (lower bound).

#### Size estimations

From gitlab-org/cluster-integration/gitlab-agent!331 (merged):

connectionsByAgentId use ConnectedAgentInfo as the value. Typical size including the wrapper is ~160 bytes.

connectionsByProjectId - same as above - ~160 bytes.

tunnelsByAgentId use TunnelInfo as the value. Typical size including the wrapper is ~130 bytes.

### Simple Summary

For a `kas` deployment with

* 2 `kas` pods
* 10 `agentk` connections

We would expect there to be

* Maximum 10 connections at a time to redis
* Approximately 0.47 requests per second
* For data storage, 4.4Kb of data, with some expiring data after 59s, and other data expiring after 5 minutes

For a `kas` deployment with

* 10 `kas` pods
* 100 `agentk` connections

We would expect there to be

* Maximum 50 connections at a time to redis
* Approximately 4.7 requests per second
* For data storage, 44Kb of data, with some expiring data after 59s, and other data expiring after 5 minutes

# Scalability

1. The `kas` chart is configured by default to autoscale by using a [HorizontalPodAutoscaler](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/hpa.yaml). The HorizontalPodAutoscaler is configured to target an average value of 100m CPU. It will initially default to two pods, with the ability to scale up to a maximum of ten. These settings will be reviewed and adjusted later as needed <https://gitlab.com/gitlab-com/gl-infra/delivery/-/issues/1548>

1. The current implmentation of the liveness check simply returns a HTTP 200 OK, so is only reliabile for basic determination of a pods health <https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/observability/metric_server.go#L59-72> . Likewise the chart configuration uses basic TCP connectivity for readiness and liveness checks <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/deployment.yaml#L61-70>

# Availability

# Durability

Kas uses redis as its primary data store. In Gitlab this is the [main redis](../redis/README.md) cluster.

# Security/Compliance

An initial security review was done at <https://gitlab.com/gitlab-com/gl-security/appsec/appsec-reviews/-/issues/30> and the summary is as follows

1. The team audited the `gitlab-agent` codebase from the `kas` part of the source code. They also audited the `agentk` to local cluster communication, and `agentk` to `kas` communication.
1. The team noted "The data flow within kas makes a good impression with respect to security practices. The only information which comes from the agent is the agent token. All other information is pulled from the GitLab API. This helps a lot to avoid logic errors and bypasses based on input from the agent. "
1. While currently every agent uses a generated token to authenticate itself to Gitlab, further expansion is needed on the authentication and authorization model of `kas` in order to better control which agent has access to which repositories (inside the users permissions structure). This is being tracked in <https://gitlab.com/gitlab-org/gitlab/-/issues/220912>

# Monitoring/Alerting

### Kibana

Select the pubsub-kas-inf-gprd-*index pattern. (pubsub-kas-inf-gstg-* for staging)

staging: <https://nonprod-log.gitlab.net/goto/9f205372ad310869528fc2cb5336baff>

production: <https://log.gprd.gitlab.net/goto/33a5e2d548b67b2247de5aa8169c47e8>

### Grafana Dashboards

Kubernetes Pods : httpis://dashboards.gitlab.net/d/kubernetes-pods/kubernetes-pods?orgId=1&var-datasource=Global&var-cluster=gstg-gitlab-gke&var-namespace=gitlab

Kube container detail : <https://dashboards.gitlab.net/d/kas-kube-containers/kas-kube-containers-detail?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gstg&var-stage=main>

<https://dashboards.gitlab.net/d/kas-kube-deployments/kas-kube-deployment-detail?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gstg&var-stage=main>

KAS pod detail: <https://dashboards.gitlab.net/d/kas-pod/kas-pod-info?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gstg&var-cluster=gstg-gitlab-gke&var-stage=main&var-namespace=gitlab&var-Node=All&var-Deployment=gitlab-kas>

Overview and SLIs : <https://dashboards.gitlab.net/d/kas-main/kas-overview?orgId=1&var-PROMETHEUS_DS=Global&var-environment=gstg&var-stage=main&var-sigma=2&from=now-15m&to=now>

### Thanos Queries

Metrics are being collected from kas via the prometheus job name `gitlab-kas`. E.g. for staging <https://thanos-query.ops.gitlab.net/graph?g0.range_input=1h&g0.max_source_resolution=0s&g0.expr=%7Bjob%3D%22gitlab-kas%22%2C%20env%3D%22gstg%22%7D&g0.tab=1>

E.g. Total agent connections - <https://thanos-query.ops.gitlab.net/new/graph?g0.expr=sum(grpc_server_requests_in_flight%7Bapp%3D%22kas%22%2C%20grpc_method%3D%22GetConfiguration%22%7D)&g0.tab=0&g0.stacked=0&g0.range_input=12h&g0.max_source_resolution=0s&g0.deduplicate=1&g0.partial_response=0&g0.store_matches=%5B%5D&g0.end_input=2021-02-01%2000%3A54%3A18&g0.moment_input=2021-02-01%2000%3A54%3A18>

Observability is continued to be worked on in <https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/12156>

The initial SLA for this service will be targeting error rates on the `GetConfiguration()` gRPC method, which should be under 1%. After launch, Configure will implement the metrics necessary for a [more relevant SLA](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/90).

# Links to further Documentation

* [Kubernetes Agent Readiness Review](https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/kubernetes-agent/index.md)
