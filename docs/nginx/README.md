<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

# NGINX Service

* **Alerts**: <https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22nginx%22%2C%20tier%3D%22sv%22%7D>
* **Label**: gitlab-com/gl-infra/production~"Service::NGINX"

## Logging

* [Kubernetes](https://log.gprd.gitlab.net/goto/88eab835042a07b213b8c7f24213d5bf)
* [Error Logs](https://cloudlogging.app.goo.gl/neeqq5jQEKWsxZRx8)

## Troubleshooting Pointers

* [Disk space alerts (production)](../customersdot/disk-space.md)
* [CustomersDot main troubleshoot documentation](../customersdot/overview.md)
* [design.gitlab.com Runbook](../design/design-gitlab-com.md)
* [HAProxy Management at GitLab](../frontend/haproxy.md)
* [Service Error Rate](../monitoring/definition-service-error-rate.md)
* [Service Operation Rate](../monitoring/definition-service-ops-rate.md)
* [Filesystem errors are reported in LOG files](../monitoring/filesystem_alerts.md)
* [monitor.gitlab.net not accessible or return 5xx errors](../monitoring/monitor-gitlab-net-not-accessible.md)
* [Gitlab.com on Kubernetes](../onboarding/gitlab.com_on_k8s.md)
* [Packagecloud Infrastructure and Backups](../packagecloud/infrastructure.md)
* [Life of a Git Request](../tutorials/overview_life_of_a_git_request.md)
* [Life of a Web Request](../tutorials/overview_life_of_a_web_request.md)
* [Managing Chef](../uncategorized/manage-chef.md)
* [Google mtail for prometheus metrics](../uncategorized/mtail.md)
* [../uncategorized/namespace-restore.md](../uncategorized/namespace-restore.md)
* [version.gitlab.com Runbook](../version/version-gitlab-com.md)
* [Nginx is down](../web/nginx-is-down.md)
<!-- END_MARKER -->

## Summary

NGINX sits in front of our Puma services.  It provides a bit of protection
between end users and puma workers to prevent saturation of threads.

## Architecture

For Virtual Machines, this is deployed via our Omnibus package and runs as a
service that recieves traffic.

For Kubernetes, this is deployed using the NGINX Ingress controller managed by
our helm chart.  <https://docs.gitlab.com/charts/charts/nginx/>

### Configuration

<https://docs.gitlab.com/omnibus/settings/nginx.html>

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
