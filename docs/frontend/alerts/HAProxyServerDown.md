# HAProxyServerDown

**Table of Contents**

[TOC]

## Overview

- [ ] What does this alert mean?
- [ ] What factors can contribute?
- [ ] What parts of the service are effected?
- [ ] What action is the recipient of this alert expected to take when it fires?

## Services

- [Service Overview](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/frontend/haproxy.md?ref_type=heads)
- Team that owns the service: [Production Engineering Foundations Team](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/gitaly/)
- **Label:** gitlab-com/gl-infra/production~"Service::HAProxy"

## Metrics

- [ ] Briefly explain the metric this alert is based on and link to the metrics catalogue. What unit is it measured in? (e.g., CPU usage in percentage, request latency in milliseconds)
- [ ] Explain the reasoning behind the chosen threshold value for triggering the alert. Is it based on historical data, best practices, or capacity planning?
- [ ] Describe the expected behavior of the metric under normal conditions. This helps identify situations where the alert might be falsely firing.
- [ ] Add screenshots of what a dashboard will look like when this alert is firing and when it recovers
- [ ] Are there any specific visuals or messages one should look for in the screenshots?

## Alert Behavior

- [ ] Information on silencing the alert (if applicable). When and how can silencing be used? Are there automated silencing rules?
- [ ] Expected frequency of the alert. Is it a high-volume alert or expected to be rare?
- [ ] Show historical trends of the alert firing e.g  Kibana dashboard

## Severities

- [ ] Guidance for assigning incident severity to this alert
- [ ] Who is likely to be impacted by this cause of this alert?
  - [ ] All gitlab.com customers or a subset?
  - [ ] Internal customers only?
- [ ] Things to check to determine severity

## Verification

- [ ] Prometheus link to query that triggered the alert
- [ ] Additional monitoring dashboards
- [ ] Link to log queries if applicable

## Recent changes

- [ ] Links to queries for recent related production change requests
- [ ] Links to queries for recent cookbook or helm MR's
- [ ] How to properly roll back changes

## Troubleshooting

- [ ] Basic troubleshooting order
- [ ] Additional dashboards to check
- [ ] Useful scripts or commands

Errors are being reported by HAProxy, this could be a spike in 5xx errors, server connection errors, or backends reporting unhealthy.

**Basic troubleshooting order**

- Examine the health of all backends and the HAProxy dashboard
  - HAProxy - <https://dashboards.gitlab.net/d/haproxy/haproxy>
  - HAProxy Backend Status - <https://dashboards.gitlab.net/d/frontend-main/frontend-overview>
- Is the alert specific to canary servers or the canary backend? Check canaries to ensure they are reporting OK. If this is the cause you should immediately change the weight of canary traffic.
  - Canary dashboard - <https://dashboards.gitlab.net/d/llfd4b2ik/canary>
  - To disable canary traffic see the [Canary ChatOps documentation](https://gitlab.com/gitlab-org/release/docs/blob/master/general/deploy/canary.md#canary-chatops)
- From a HAProxy node, ping and/or curl the backend server and health check.
- From a HAProxy node, check the logs of the process.

**Useful scripts or commands**

- Check the health of the deployment in Kubernetes:

  ```bash
  kubectl --namespace gitlab get deployment gitlab-gitlab-shell
  kubectl --namespace gitlab get pods --selector app=gitlab-shell
  ```

- HAProxy logs are not currently being sent to ELK because of capacity issues. More information can be read [here](./haproxy-logging.md).
- If the errors are from pages backends, consider possible intentional abuse or accidental DoS from specific IPs or for specific domains in Pages. Client IPs can be identified by volume from the current HAProxy logs on the Haproxy nodes with:
  ```
  sudo grep -v check_http /var/log/haproxy.log | awk '{print $6}' | cut -d: -f1|sort|uniq -c |sort -n|tail
  ```

- To block: In <https://gitlab.com/gitlab-com/security-tools/front-end-security> edit `deny-403-ips.lst`. Commit, push, open MR, ensure it has pull mirrored to `ops.gitlab.net`, then run chef on the pages HAProxy nodes to deploy. This will block that IP across *all* frontend (pages, web, api etc), so be sure you want to do this.
- Problem sites/projects/domains can be identified with the `Gitlab-Pages activity` dashboard on Kibana - <https://log.gprd.gitlab.net/app/kibana#/dashboard/AW6GlNKPqthdGjPJ2HqH>
- To block: In <https://gitlab.com/gitlab-com/security-tools/front-end-security> edit `deny-403-ips.lst`. Commit, push, open MR, ensure it has pull mirrored to `ops.gitlab.net`, then run chef on the pages HAProxy nodes to deploy. This will block only the named domain (exact match) in pages, preventing the request ever making it to the pages deployments. This is low-risk.

*Note*: HAProxy forks on reload and old processes will continue to service requests, for long-lived SSH connections we use the `hard-stop` configuration parameter to prevent processes from lingering more than `5` minutes. 
In <https://gitlab.com/gitlab-com/gl-infra/delivery/issues/588> we have observed that processes remain for longer than this interval, this may require manual intervention:

- Display the process tree for HAProxy (2 processes instead of 1 expected):

```
pstree -pals $(pgrep -u root -f /usr/sbin/haproxy)
systemd,1 --system --deserialize 36
  └─haproxy,28214 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827
      ├─haproxy,1827 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
      └─haproxy,2002 -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf
```

- Show the elapsed time of the haproxy processes:

```
# for p in $(pgrep -u haproxy -f haproxy); do ps -o user,pid,etimes,command $p; done
USER       PID ELAPSED COMMAND
haproxy   1827   99999 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1639
USER       PID ELAPSED COMMAND
haproxy   2002      20 /usr/sbin/haproxy -Ws -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf 1827

```

- Kill the process with the longer elapsed time:

```
kill -TERM 1827
```





## Possible Resolutions

- [ ] Links to past incidents where this alert helped identify an issue with clear resolutions

## Dependencies

- [ ] Internal and external dependencies which could potentially cause this alert

# Escalation

- [ ] How and when to escalate
- [ ] Slack channels where help is likely to be found:

# Definitions

- [ ] Link to the definition of this alert for review and tuning
- [ ] Advice or limitations on how we should or shouldn't tune the alert
- [ ] Link to edit this playbook
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)

# Related Links

- [Related alerts](./)
- [ ] Related documentation
- [Update the template used to format this playbook](https://gitlab.com/gitlab-com/runbooks/-/edit/master/docs/template-alert-playbook.md?ref_type=heads)
