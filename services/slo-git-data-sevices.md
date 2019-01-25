# SLO and Error budget policy for Git Data on GitLab.com

This document describes the SLOs for services that serve data from Git repositories on GitLab.com

## Status: Draft
### Approval Date:
### Review Date:

## Service Overview
GitLab.com serves remote git repositories for all paying and free users.  Our users interact with their git remotes via https (port 443) and ssh (port 22).

We have a dedicated set of load balancers for both https and ssh traffic.  We keep diagrams on the infrastructure team handbook [architecture page](https://about.gitlab.com/handbook/engineering/infrastructure/production-architecture/)

The SLO uses a four week rolling window.


## SLIs and SLOs

### Git over https
#### Availability
99.95% success.  The proportion of successful requests as measured from our load balancer metrics.  Any HTTP status other than 500 - 599 is considered successful.

count of git http_requests which do not have a 5xx status code divided by the count of all git http_requests

Example from prometheus:

Error: sum(increase(haproxy_backend_http_responses_total{backend="https_git", code="5xx"}[7d]))
Total: sum(increase(haproxy_backend_http_responses_total{backend="https_git"}[7d]))

Error is 7161 and Total is 254,490,134. So we have a 99.95% error budget of 254490134 * .0005 = 127,245 for the week and are well inside the budget.
Each week we can update a table with our total count against budget.

#### Latency
90% of requests < .5 second
99% of requests < 1 second

The proportion of sufficiently fast requests as measured from our load balancer metrics.
a duration of less than or equal to 10s (p90) for all http_requests

on https://prometheus-app.gprd.gitlab.net/graph
gitlab_workhorse_http_request_duration_seconds_bucket

histogram_quantile(0.99, sum(rate(gitlab_workhorse_http_request_duration_seconds_bucket{job="gitlab-workhorse-git"}[1h])) by (le))
Currently this may be hard to get at a larger scale.  The example above gets a 1h p99 of:

| p99 (s) | Date Time |
|---------|-----------|
| .525   | 2019-01-22T18:00Z |
| .616   | 2019-01-15T18:00Z |
| .668   | 2019-01-08T18:00Z |

## Rational
Availability and Latency SLIs were based on measurements over the period from 2018-12-27 to 2019-01-27.

No attempt has been made to verify these numbers correlate strongly with good user experience.  This is a first draft SLI/SLO document intended to be a starting point.


## Error Budget
Each objective SLO will have an error budget as defined by 100% minus the goal for the objective time period.  For example, if we recieve 100,000 requests in the previous week with a 99.95% availability SLO, we have an error budget of (100,000 - 99,950) 50 requests.

The error budge policy is to be implemented once we have exceeded the budget.


## Clarification and Caveats

* Request metrics measured from the load balancer will not take into account situations where the load balancer does not ship metrics for various reasons - general network issues or availability issues with metric collection.

-------------------------------------------

# Error Budget Policy

### Goals
The goals of the policy are to:
1. Protect users from repeated SLO misses
2. Provide and incentive to balance reliability with improvements to the system and feature delivery

Non-Goals: The policy is not intended to be a punishment for missing SLO targets.  Halting change is not the goal, this policy gives teams a way to measure when we need to focus exclusively on reliability.


### SLO Miss Policy

If the service is performing at or above its SLO, then releases and maintenance will proceed according to our exisitng change management and release policies.

If the service has exceeded its error budget for the preceeding 4 week window, we will halt all planned maintenance changes other than production incident remediations until the service is back within its SLO.

The team must work on reliability if:

1. A change related to a planned C1-C4 change issue caused the service to exceed the error budget.
2. Mis-categoried errors or incidents fail to consume budget that would have caused the service to miss its SLO.

The team may continue to work on non-reliability if:

1.  The outage was caused by a Cloud Service Provider incident for which no extra redundancy would have provided cover.
2.  Miscategorized errors consume budget even though no users were impacted.

### Outage Policy
If a single incident consumes more that 20% of error budget over the 4 week rolling period, the team must conduct an RCA.  That RCA should contain at least one P1 action item to address the root cause.

### Escalation Policy

If there is a disagreement over application or calculation of the policy, the issue should be taken to the Director of Infrastructure or VP of Engineering to make a decision.
